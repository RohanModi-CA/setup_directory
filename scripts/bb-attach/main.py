import tkinter as tk
import subprocess
import os

def get_nth_most_recent_subdir(directory, n):
    """
    Finds the nth most recently modified subdirectory within a directory.

    Args:
        directory (str): The directory to search.
        n (int): The desired ranking (1 for most recent, 2 for second most, etc.).

    Returns:
        str: The path to the nth most recent subdirectory, or None if not found.
    """
    try:
        command = [
            "find",
            directory,
            "-maxdepth", "1",
            "-type", "d",
            "-not", "-path", directory,
            "-printf", "%T+ %p\n"
        ]
        process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        stdout, stderr = process.communicate()

        if stderr:
            print(f"Error running find: {stderr.decode()}")
            return None

        output = stdout.decode().strip()
        if not output:
            print("No subdirectories found.")
            return None

        lines = output.splitlines()
        sorted_lines = sorted(lines, reverse=True)  # Sort by timestamp (most recent first)

        if n > len(sorted_lines):
            print(f"Only {len(sorted_lines)} subdirectories found. Cannot retrieve the {n}th most recent.")
            return None

        path = sorted_lines[n - 1].split(" ", 1)[1].strip()
        return path

    except FileNotFoundError:
        print("Error: find command not found. Make sure it's in your PATH.")
        return None
    except Exception as e:
        print(f"An unexpected error occurred: {e}")
        return None


def open_nautilus(directory):
    """Opens the specified directory in Nautilus file manager."""
    try:
        subprocess.Popen(["nautilus", directory])
    except FileNotFoundError:
        print("Error: nautilus command not found. Make sure it's installed.")
    except Exception as e:
        print(f"Error opening Nautilus: {e}")


def create_button_command(n, directory):
    """
    Creates a command to be executed when a button is clicked.

    Args:
        n (int): The rank of the subdirectory to open (1 for most recent, etc.).
        directory (str): The base directory to search in.

    Returns:
        function: A function that finds the nth most recent subdirectory and opens it in Nautilus.
    """
    def command():
        subdir = get_nth_most_recent_subdir(directory, n)
        if subdir:
            open_nautilus(subdir)

    return command


def create_gui(directory):
    """Creates the Tkinter GUI."""
    root = tk.Tk()
    root.title("N Most Recent Subdirectories")

    buttons = []
    for i in range(1, 6):  # Create buttons for 1st to 5th most recent
        button = tk.Button(root, text=f"{i}st Most Recent", command=create_button_command(i, directory))
        buttons.append(button)
        button.pack(pady=5)

    root.mainloop()


if __name__ == "__main__":
    target_directory = "/home/gram/.var/app/app.bluebubbles.BlueBubbles/data/bluebubbles/attachments"

    # Check if the directory exists before starting the GUI
    if not os.path.isdir(target_directory):
        print(f"Error: Directory '{target_directory}' does not exist.")
    else:
        create_gui(target_directory)
