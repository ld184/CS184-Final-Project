# Milestone Status Report - GenshinLeRF

## **Team 27 members:**
Rahul Shah, 3035895524, rsha256@ \
Levy Deng, 3034878718, dengchun@\
Pierre Le, 3034785443, piele@\
Jason Yang, 3034715529, jasonyang@


# Problem Description
From lecture and projects we've learned how to apply shaders on top of meshes, and with the onset of state of the art rendering techniques using NeRF, we thought it would be interesting to merge the two ideas together -- why not try to apply LeRF / NeRF into game scenes, instead of simply pictures.


[Presentation Slides](https://docs.google.com/presentation/d/1ieyfF-WIbSOtk5pmJEToSlXEdF1hzmLQnvzZBNA144k/edit?usp=sharing)

[Milestone Video 1](https://youtu.be/WW-me9ghazs)

[Milestone Video 2](https://www.youtube.com/watch?v=TyItN_ANp9s)



# Accomplishments
### **Shaders**
We're able to fully inject and attach a DLL to hijact the back and depth buffer of Genshin Impact, and we also were able to code out a non-photorealistic / stylized shader for the game based on Kuwahara filters on the GPU in a language similar to HLSL. Additionally, we're able to tune the shader parameters (uniforms) inside the game itself, allowing for dynamic adjustments to the shader effects. Checkout our Milestone 1 for a demo for what the shaders look like in action.

### **NeRF**
We have been able to run NeRF studio and create a NeRF based on a short recording of the game. To do this, we start by recording a short 3-10s video of the game. We process the video by running it through COLMAP to solely extract camera poses. Using the camera poses and the frames of the video, we can feed this to NeRF studio to train. 
### **LeRF**
We have acquired the code for LeRF and have integrated it into NeRF studio. We are able to run LeRF but we did not start training yet.

# Preliminary results

<table>
  <tr>
    <td> <img src="images/shaders1.png" ></td>
    <td><img src="images/shaders2.png" > </td>
  </tr> 
  <tr>
    <td><img src="images/nerf1.png"></td>
    <td><img src="images/nerf2.png"></td>
  </tr>
</table>

# Reflection on progress
We are definitely on track to finishing up all our deliverables. With shaders being done, we can redirect a lot of attention to getting LeRF integrated into a game engine where camera poses can be exposed as opposed to processing and guessing camera poses after the fact. While We had many issues trying to install NeRF studio and COLMAP(g++ version and CUDA version incompatibilities, Google Colab not rendering), we resolved them all. Processing and training a NeRF with more images should be doable in a reasonable time on decent hardware.

# Update to Work Plan
We saw that using COLMAP might take a long time to extract camera poses for longer videos. If we have time, we could get camera poses directly from the game engine and skip using COLMAP. This would speed up our pipeline of creating NeRF. There is also a way to speed up training for the NeRF using [Instant NGP](https://github.com/NVlabs/instant-ngp). We also plan on adding more shaders for more variety like Black an white retro shader with stylized edges, and generalized and anistropic kuwahara filters. With all shading techniques combined together into black and white toon shaders, and pastel toon shader.


# References + Resources
[Proposal](https://ld184.github.io/CS184-Final-Project/)

[Project Feedback](https://docs.google.com/document/d/1ACxvGXqYXTVl7j1KEwd1y96VBymK9Eb6j7ZG5sVImrA/edit)

[Presentation Slides](https://docs.google.com/presentation/d/1ieyfF-WIbSOtk5pmJEToSlXEdF1hzmLQnvzZBNA144k/edit?usp=sharing)

[Milestone Video 1](https://youtu.be/WW-me9ghazs)

[Milestone Video 2](https://www.youtube.com/watch?v=TyItN_ANp9s)