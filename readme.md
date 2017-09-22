# Anim8 Space (iOS)

When making stop motion animations, it is critical that the camera does not move involuntarily between one frame and the next. This is normally achieved by affixing the camera to a tripod. To achieve the same effect when the camera is hand-held, Anim8 instead uses image stabilization software, where each frame of the animation is aligned to the first frame.
 
Anim8 was developed as part of a research project at University College London (UCL) and Southampton University. 
The app although fully functional was developed as a prototype and as such may be lacking in some areas. The project source is available and we are open to pull requests to enhance the code base.

## More Information about the project

For more information about Anim8 and the research it was developed for, please visit: http://www.anim8.space

## Installation

The project should require little setup, just add it to Xcode. However you will need to download and add the Opencv framework from: http://opencv.org/releases.html. Drag and drop the .framework file to your projects 'Project Navigator' (Do not drop in the folder structure directly). Make sure you check the box labelled 'copy files if necessary'. This should now let you compile without errors. If it doesn't then check then check your build settings. 