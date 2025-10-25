# SinkManager

A simple graphical tool for managing virtual audio sinks (null sinks) on Linux using PulseAudio or PipeWire.



---

## Purpose 🎧

SinkManager provides an easy way to:
* **Create** new virtual audio output devices (sinks).
* **View** existing virtual sinks you've created.
* **Delete** virtual sinks you no longer need.

Virtual sinks are useful for routing audio between different applications without needing physical cables. For example, you can send audio from an SDR application to a decoding application like JAERO.

---

## Requirements 🐧

* A Linux distribution.
* **PulseAudio** or **PipeWire** installed and running (most modern desktops use one of these).
* The `pactl` command-line utility must be available (this is usually installed by default with PulseAudio/PipeWire).

---

## How to Use

1.  **Run the Application:**
    * Download the `SinkManager` executable
    * Make it executable: `chmod +x SinkManager`
    * Run it: `./SinkManager`

2.  **Main Window:**
    * The main window displays a list of your current virtual audio sinks created by `module-null-sink`.
    * Each entry shows the **Sink Name** and its **Description**.

    

3.  **Create a Sink:**
    * Click the **"+ Create Sink"** button in the top-right corner.
    * Enter a descriptive name for your new sink (e.g., `JAERO_Sink`, `OBS_Input`) in the dialog box. Avoid spaces or special characters for maximum compatibility.
    * Click **"Create"**.
    * The new sink will appear in the list (you might need to click Refresh).

    

4.  **Delete a Sink:**
    * Find the sink you want to remove in the list.
    * Click the **red trash can icon** (🗑️) on the right side of the sink's entry.
    * Confirm the deletion in the dialog box.
    * **Caution:** Deleting a sink will disconnect any applications currently sending audio to it or receiving audio from its monitor source.

5.  **Refresh List:**
    * Click the **Refresh icon** (🔄) in the top-right corner to reload the list of sinks from PulseAudio/PipeWire. This is useful if you've made changes outside the app.

6.  **Close Application:**
    * Click the **Close icon** (❌) in the top-right corner to exit SinkManager.

---

## Using Your Virtual Sinks

Once you create a virtual sink (e.g., `MySink`):

* **Output:** In applications that can select an audio output (like SDR++, VLC, Firefox), you can choose `MySink` as the output device. Audio sent there will go nowhere unless something is listening to its monitor.
* **Input:** In applications that can select an audio input (like Audacity, OBS, JAERO), you can often choose `Monitor of MySink` as the input device. This allows the application to "hear" whatever audio is being sent to `MySink`.

This setup effectively creates a virtual audio cable within your system. 👍