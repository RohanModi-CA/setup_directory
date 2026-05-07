#!/usr/bin/env python3
import tkinter as tk
from pathlib import Path

SAVE_FILE = Path.home() / ".library_message.txt"
FONT_SIZE = 100

def save_and_close(event=None):
    text = text_widget.get("1.0", "end-1c")
    SAVE_FILE.write_text(text)
    root.destroy()

root = tk.Tk()
root.title("Message")

# Make window reasonably large
root.geometry("1200x400")
root.update_idletasks()
w = 1200
h = 400
ws = root.winfo_screenwidth()
hs = root.winfo_screenheight()
x = (ws - w) // 2
y = (hs - h) // 2
root.geometry(f"{w}x{h}+{x}+{y}")


text_widget = tk.Text(
    root,
    font=("Helvetica", FONT_SIZE),
    wrap="word"
)

def select_all(event=None):
    text_widget.tag_add("sel", "1.0", "end")
    text_widget.mark_set("insert", "1.0")
    text_widget.see("insert")
    return "break"

text_widget.bind("<Control-a>", select_all)
text_widget.bind("<Control-A>", select_all)

text_widget.pack(expand=True, fill="both")

# Load previous text if it exists
if SAVE_FILE.exists():
    text_widget.insert("1.0", SAVE_FILE.read_text())

text_widget.focus_set()

# Press Enter to save + close
root.bind("<Return>", save_and_close)

# Optional: Esc also closes
root.bind("<Escape>", save_and_close)

root.mainloop()
