# Milestone Status Report - GenshinLeRF

## **Team 27 members:**
Rahul Shah, 3035895524, rsha256@ \
Levy Deng, 3034878718, dengchun@\
Pierre Le, 3034785443, piele@\
Jason Yang, 3034715529, jasonyang@


# Problem Description
From lecture and projects we've learned how to apply shaders on top of meshes, and with the onset of state of the art rendering techniques using NeRF, we thought it would be interesting to merge the two ideas together -- why not try to apply LeRF / NeRF into game scenes, instead of simply pictures.


[Presentation Slides](TODO)

[Milestone Video](TODO)

# Accomplishments
### **Shaders**
TODO 

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
      <td><img src="images/nerf2.png">
  </td>
  </tr>
</table>

# Reflection on progress
We are definitely on track to finishing up all our deliverables. We are still working on shaders and plan to train a LeRF in the following week. We had many issues trying to install NeRF studio and COLMAP, but we have resolved them. Processing and training a NeRF with more images should be doable in a reasonable time. 

# Update to Work Plan
We saw that using COLMAP might take a long time to extract camera poses for longer videos. If we have time, we could get camera poses directly from the game engine and skip using COLMAP. This would speed up our pipeline of creating NeRF. There is also a way to speed up training for the NeRF using [Instant NGP](https://github.com/NVlabs/instant-ngp). 


# References + Resources
[Proposal](https://ld184.github.io/CS184-Final-Project/)

[Project Feedback](https://docs.google.com/document/d/1ACxvGXqYXTVl7j1KEwd1y96VBymK9Eb6j7ZG5sVImrA/edit)

[Presentation Slides](TODO)

[Milestone Video](TODO)