// BladeWatch-rdtj.66: let the camera daemon survive vold's SIGINT.
//
// When the SD card is unmounted (BYD's ACC OFF shutdown does it), vold sends SIGINT to every
// process holding a file on the card, waits 5 s, retries the unmount, then escalates to SIGTERM and
// SIGKILL. By default SIGINT ends the daemon (exit 130), costing ~25 s of no dashcam or sentry while
// the watchdog restarts it (rdtj.65). ART on this head unit has no sun.misc.Signal (measured
// 2026-09-27: ClassNotFoundException), so the handler lives here: it only writes a byte to a pipe --
// write() is async-signal-safe -- and a Java thread blocked in nativeAwait() does the real work of
// closing what the daemon holds on the card, in time for vold's retry.
#include <jni.h>
#include <csignal>
#include <cerrno>
#include <fcntl.h>
#include <unistd.h>

namespace {
int g_pipe[2] = {-1, -1};

void onSignal(int) {
    const int saved = errno;
    const char byte = 1;
    // Nothing to do if the pipe is full: a wake-up is already pending.
    (void) write(g_pipe[1], &byte, 1);
    errno = saved;
}
}  // namespace

extern "C" JNIEXPORT jboolean JNICALL
Java_net_bladewatch_app_daemon_SdCardSignal_nativeInstall(JNIEnv*, jclass) {
    if (g_pipe[0] >= 0) return JNI_TRUE;
    if (pipe2(g_pipe, O_CLOEXEC) != 0) return JNI_FALSE;
    fcntl(g_pipe[1], F_SETFL, O_NONBLOCK);
    struct sigaction action {};
    action.sa_handler = onSignal;
    sigemptyset(&action.sa_mask);
    action.sa_flags = SA_RESTART;
    return sigaction(SIGINT, &action, nullptr) == 0 ? JNI_TRUE : JNI_FALSE;
}

// Blocks until a SIGINT arrives; false if the pipe is gone.
extern "C" JNIEXPORT jboolean JNICALL
Java_net_bladewatch_app_daemon_SdCardSignal_nativeAwait(JNIEnv*, jclass) {
    char byte;
    for (;;) {
        const ssize_t n = read(g_pipe[0], &byte, 1);
        if (n == 1) return JNI_TRUE;
        if (n < 0 && errno == EINTR) continue;
        return JNI_FALSE;
    }
}
