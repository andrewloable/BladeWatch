package com.overdrive.app.daemon.telegram;

import org.json.JSONObject;

/**
 * Context for command execution - provides messaging and utility methods.
 */
public interface CommandContext {
    
    /**
     * Send a text message to the chat.
     */
    boolean sendMessage(long chatId, String text);
    
    /**
     * Send a text message with inline keyboard buttons.
     * @param buttons Array of button rows, each row is array of [text, callbackData] pairs
     */
    boolean sendMessageWithButtons(long chatId, String text, String[][][] buttons);
    
    /**
     * Send a video to the chat.
     */
    boolean sendVideo(long chatId, String videoPath, String caption);
    
    /**
     * Send an IPC command to a local service.
     */
    JSONObject sendIpcCommand(int port, JSONObject command);

    /**
     * Send an IPC command with a custom socket read timeout. Use when the
     * server-side handler may legitimately take longer than the default
     * (e.g. GitHub API calls in update flow). Default impl falls back to
     * the 5s-timeout method so existing impls don't break.
     */
    default JSONObject sendIpcCommand(int port, JSONObject command, int timeoutMs) {
        return sendIpcCommand(port, command);
    }
    
    /**
     * Execute a shell command and return output.
     */
    String execShell(String command);
    
    /**
     * Log a message.
     */
    void log(String message);
}
