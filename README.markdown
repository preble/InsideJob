## Inside Job

### A Minecraft Alpha Inventory Editor for Mac OS X

![Inside Job Screenshot](Screenshot.png)

Inside Job was written in early October 2010 by [Adam Preble](http://adampreble.net).

Features include:

- Native Cocoa interface.
- Drag and drop inventory editing with item images.
- Item list searchable by name or item number.
- Experimental "time of day" editing.

### System Requirements

Mac OS X 10.6 Snow Leopard.

### Instructions

Inside Job operates on Minecraft's level.dat files, located in _~/Library/Application Support/minecraft/saves/World*_.  While Inside Job was written to interact with Minecraft's data as safely as possible, it's entirely possible that it will destroy it completely.  Please back up your Minecraft saves folder before using Inside Job.

Be sure to save and exit any open Minecraft worlds before running Inside Job.  Once run, Inside Job will open the first world and display your inventory.  You can change worlds using Command-1 thru 5, or using the segmented control at the top of the main window.  Note that Inside Job can only edit existing worlds.

To alter your inventory, use the item list at right to find the item you desire, then drag it into an  inventory slot.  Rearrange items by dragging them to different slots.  To copy an item, including its quantity, hold the Option key when you start dragging.

Note that Inside Job works differently from the Minecraft inventory screen in that it does not "swap" items when dropping an item onto another.  Instead, it replaces the item completely.  If you drag an item into a slot already containing that item, the quantity will be increased accordingly, up to 64.

To alter the quantity or damage of a particular item, click on its inventory slot.  To accept the changes, hit escape or click outside of the popup window.

After changing your inventory you will need to save the currently open world using the World menu, or Command-S.  Once you have saved the world you can open it in Minecraft.  Note that if a world is opened in Minecraft while it is open in Inside Job, you will need to re-open it by switching to another world before switching back.  This is because Minecraft's file locking system gives write access to the last program to open it.

### Credits

Inside Job uses [Matt Gemmell](http://mattgemmell.com/)'s MAAttachedWindow.  Item graphics were originally created by Mojang Specifications and compiled by Trojam and the Minecraft community.

### License

Inside Job is made available under the [MIT License](http://www.opensource.org/licenses/mit-license.html).  Its source code can be found on GitHub: [http://github.com/preble/InsideJob]().

	Copyright (c) 2010 Adam Preble

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in
	all copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
	THE SOFTWARE.
