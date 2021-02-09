# Human Rescue Lander (Nokia Jam 3)

[![Human Rescue Lander Video Link](http://img.youtube.com/vi/mSo2IYfajHs/0.jpg)](http://www.youtube.com/watch?v=mSo2IYfajHs "Human Rescue Lander Video")

This repo is for the sourcecode of the Nokia Jam 3 entry "Human Rescue Lander". You can play the game in the browser under the following link:
https://ssero.itch.io/human-rescue-lander

I decided to upload the sourcecode for others to study since there are not yet enough resources to learn from for the DragonRuby Game Toolkit. This was my first time using DragonRuby GTK for a finished game so I had to learn the engine as I was developing the game. While this sourcecode is not meant as a recommendation of how to structure or properly code a game in general, I still remain hopeful that it's somewhat useful for beginners, as it covers some basic things in a very simple manner.

Instructions:
1. Download the /mygame/ folder from Github
2. Download the DragonRuby Game Toolkit (e.g. http://nokiajam.dragonruby.org.s3-website-us-east-1.amazonaws.com/)
3. Unzip the archive to some folder on your harddrive
4. Go to the /mygame/ folder from the DragonRuby Game Toolkit zip-archive and replace it with Github version
5. Start the dragonruby.exe (the game should start and be playable in a window)
6. Go to the /mygame/app/ folder and open main.rb with your favorite text editor
7. Edit the sourcecode while the dragonruby.exe is still running in the background. You can now live edit the game

Self-critique:
- One of the goals of the Nokia jam was to be faithful to the limits of the old system. While I adhered to the resolution and palette, using scrolling the way I used it would most likely been impossible on original hardware because of the ghosting of the screen. Everything would turn into a blurry mess (Gameboy anyone?). Also the buttons would not be responsive enough to facilitate the needed reaction time to play the game properly.
- The gameplay is not suited for a mostly horizontal screen (being a game about vertical gravity). When I started I just fiddled around without any idea what game I should make and it turned into a gravity-based game. Ideally you would take the aspect-ratio of the screen into consideration when developing the game mechanic.
- I think I found an interesting risk-reward mechanic with the time-limit and punishing gravity which might be worth exploring further. The first thing to improve / change would be the field of view and aspect-ratio. Additionally, instead of increasing the things to collect per level I would add things in the sky which would damage you on contact, so you would have to become better at maneuvering, not only on the floor, but also in the air.

If you have any feedback or questions, please feel free to contact me via Twitter https://twitter.com/ssero/
