// SPDX-License-Identifier: GPL-2.0-only
#define _GNU_SOURCE

#include <errno.h>
#include <dirent.h>
#include <fcntl.h>
#include <linux/input-event-codes.h>
#include <linux/input.h>
#include <linux/uinput.h>
#include <signal.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/stat.h>
#include <time.h>
#include <unistd.h>

#define DEVICE_NAME "Nabu Tablet Mode Switch"
#define USER_SHELL_DELAY_TICKS 25
#define POLL_NSEC 200000000L

static volatile sig_atomic_t stopping;
static volatile sig_atomic_t retrigger;

static void handle_signal(int signal_number)
{
	(void)signal_number;
	stopping = 1;
}

static void handle_usr1(int signal_number)
{
	(void)signal_number;
	retrigger = 1;
}

static int emit_event(int fd, unsigned short type, unsigned short code,
		      int value)
{
	struct input_event event = {
		.type = type,
		.code = code,
		.value = value,
	};
	ssize_t written;

	written = write(fd, &event, sizeof(event));
	if (written == (ssize_t)sizeof(event))
		return 0;

	if (written >= 0)
		errno = EIO;
	return -1;
}

static int set_tablet_mode(int fd, bool enabled)
{
	if (emit_event(fd, EV_SW, SW_TABLET_MODE, enabled ? 1 : 0) < 0)
		return -1;

	return emit_event(fd, EV_SYN, SYN_REPORT, 0);
}

static bool graphical_user_shell_running(void)
{
	struct dirent *entry;
	DIR *proc;
	bool found = false;

	proc = opendir("/proc");
	if (!proc)
		return false;

	while ((entry = readdir(proc))) {
		char path[64];
		char cmdline[256];
		char comm[32];
		struct stat statbuf;
		ssize_t cmdline_length;
		ssize_t length;
		int comm_fd;
		int cmdline_fd;
		char *end;
		long pid;

		pid = strtol(entry->d_name, &end, 10);
		if (*entry->d_name == '\0' || *end != '\0' || pid <= 0)
			continue;

		(void)snprintf(path, sizeof(path), "/proc/%ld", pid);
		if (stat(path, &statbuf) < 0 || statbuf.st_uid < 1000 ||
		    statbuf.st_uid == 65534)
			continue;

		(void)snprintf(path, sizeof(path), "/proc/%ld/comm", pid);
		comm_fd = open(path, O_RDONLY | O_CLOEXEC);
		if (comm_fd < 0)
			continue;
		length = read(comm_fd, comm, sizeof(comm) - 1);
		close(comm_fd);
		if (length <= 0)
			continue;
		comm[length] = '\0';
		if (strcmp(comm, "gnome-shell\n") != 0 &&
		    strcmp(comm, "gnome-shell") != 0)
			continue;

		/*
		 * GDM also runs gnome-shell, commonly under a dynamically allocated
		 * UID above 1000.  Do not treat the greeter as the user's shell: if
		 * tablet mode is enabled before the real session starts, the new
		 * Mutter instance can inhibit orientation tracking during its native
		 * portrait initialization and never receive a later OFF -> ON edge.
		 */
		(void)snprintf(path, sizeof(path), "/proc/%ld/cmdline", pid);
		cmdline_fd = open(path, O_RDONLY | O_CLOEXEC);
		if (cmdline_fd >= 0) {
			cmdline_length = read(cmdline_fd, cmdline,
					      sizeof(cmdline));
			close(cmdline_fd);
			if (cmdline_length > 0 &&
			    memmem(cmdline, (size_t)cmdline_length,
				   "--mode=gdm", strlen("--mode=gdm")))
				continue;
		}

		found = true;
		break;
	}

	closedir(proc);
	return found;
}

int main(int argc, char **argv)
{
	struct uinput_setup setup = {
		.id = {
			.bustype = BUS_HOST,
			.vendor = 0x2717,
			.product = 0x0001,
			.version = 1,
		},
	};
	struct sigaction action = {
		.sa_handler = handle_signal,
	};
	struct sigaction usr1_action = {
		.sa_handler = handle_usr1,
		.sa_flags = SA_RESTART,
	};
	int fd;
	int status = EXIT_FAILURE;
	unsigned int shell_ticks = 0;
	bool enabled = false;

	if (argc != 1) {
		fprintf(stderr, "usage: %s\n", argv[0]);
		return EXIT_FAILURE;
	}

	fd = open("/dev/uinput", O_WRONLY | O_NONBLOCK | O_CLOEXEC);
	if (fd < 0) {
		perror("open /dev/uinput");
		return EXIT_FAILURE;
	}

	if (ioctl(fd, UI_SET_EVBIT, EV_SW) < 0 ||
	    ioctl(fd, UI_SET_SWBIT, SW_TABLET_MODE) < 0) {
		perror("configure uinput tablet switch");
		goto out_close;
	}

	(void)snprintf(setup.name, sizeof(setup.name), "%s", DEVICE_NAME);
	if (ioctl(fd, UI_DEV_SETUP, &setup) < 0 || ioctl(fd, UI_DEV_CREATE) < 0) {
		perror("create uinput tablet switch");
		goto out_close;
	}

	/*
	 * Start in laptop mode.  Mutter gives native-portrait panels one initial
	 * accelerometer update before applying tablet-mode policy.  Advertising ON
	 * before that update makes Mutter inhibit the sensor immediately afterwards.
	 */
	if (set_tablet_mode(fd, false) < 0) {
		perror("initialize tablet mode switch");
		goto out_destroy;
	}

	printf(DEVICE_NAME ": SW_TABLET_MODE=OFF; waiting for a graphical user shell\n");
	fflush(stdout);

	sigemptyset(&action.sa_mask);
	if (sigaction(SIGINT, &action, NULL) < 0 ||
	    sigaction(SIGTERM, &action, NULL) < 0) {
		perror("sigaction");
		goto out_destroy;
	}

	sigemptyset(&usr1_action.sa_mask);
	if (sigaction(SIGUSR1, &usr1_action, NULL) < 0) {
		perror("sigaction SIGUSR1");
		goto out_destroy;
	}

	while (!stopping) {
		struct timespec delay = {
			.tv_nsec = POLL_NSEC,
		};

		if (retrigger) {
			retrigger = 0;
			if (enabled) {
				if (set_tablet_mode(fd, false) < 0)
					perror("disable tablet mode on retrigger");
				enabled = false;
				shell_ticks = 0;
				printf(DEVICE_NAME ": SW_TABLET_MODE=OFF (pulsed for wake/retrigger)\n");
				fflush(stdout);
			}
		}

		if (graphical_user_shell_running()) {
			if (shell_ticks < USER_SHELL_DELAY_TICKS)
				shell_ticks++;
			if (!enabled && shell_ticks == USER_SHELL_DELAY_TICKS) {
				if (set_tablet_mode(fd, true) < 0) {
					perror("enable tablet mode");
					goto out_destroy;
				}
				enabled = true;
				printf(DEVICE_NAME ": SW_TABLET_MODE=ON\n");
				fflush(stdout);
			}
		} else {
			shell_ticks = 0;
			if (enabled) {
				if (set_tablet_mode(fd, false) < 0) {
					perror("disable tablet mode");
					goto out_destroy;
				}
				enabled = false;
				printf(DEVICE_NAME ": SW_TABLET_MODE=OFF; graphical user shell exited\n");
				fflush(stdout);
			}
		}

		while (!stopping && nanosleep(&delay, &delay) < 0 && errno == EINTR)
			;
	}

	status = EXIT_SUCCESS;
	if (enabled && set_tablet_mode(fd, false) < 0)
		perror("disable tablet mode");

out_destroy:
	if (ioctl(fd, UI_DEV_DESTROY) < 0)
		perror("destroy uinput tablet switch");
out_close:
	close(fd);
	return status;
}
