# GenshinLeRF

## Pierre Le, Rahul Shah, Jason Yang, Levy Deng



# Problem Description
From lecture and projects we've learned how to apply shaders on top of meshes, and with the onset of state of the art rendering techniques using NeRF, we thought it would be interesting to merge the two ideas together -- why not try to apply LeRF / NeRF into game scenes, instead of simply pictures.


## Lots of Problems, Not many answers
NeRF is fundamentally encoding objects and primitives into a neural network. Demos exists for application of NeRF in projects like LeRF (Language encoded Radiance Fields), which applies shading on top of scenes indicating primitives that belong to text input. Embedding this technology into a game engine is not trivial either, since the rendering pipeline has become fairly complex at this point. This brought to us the idea of shaders, why not take an existing game, inject shaders into it, and allow NeRF to interact with the rendering engine that way? Unfortunately, the answer to this question is not trivial either.


## Why it is non-trivial

Firstly, released games does not generally support post-modifications to the game files to add functionality to the game, even if it's just simple graphics modifications. In fact, in most cases, game developers goes out of their way to make it hard for users to modify their game post-production, in broad strokes using anti-cheat software. To get our shaders working, we have to modify the rendering pipeline of the game to apply those shaders, which means we have to subvert the measures of anti-modification, or to use drivers in the GPU themselves to support these shaders.
Even if we are able to get shaders working, there is no guarantee that NeRF would behave exactly as expected, since we need to capture the frame buffer to feed to NeRF as input, which effectively means we are introducing NeRF as part of the last stage of the rendering pipeline. This means that, although it could allow us to potentially add interesting shading effects - like LeRF - it also means that we need to train models to exploit the encoding provided by NeRF, and these models would be extremely purpose specific. This integration is also non-trivial.

## Our Method of Attack

To resolve our firsts challenge of making post-modifications to the game files to support shaders, we will use a game which already has either their defense mechanisms subverted (most Unity-derived games fit into this category due to their il2cpp), and an injector working for us, so to allow us to focus solely on creating the shaders and tuning them for the game.

To resolve the difficulty of attaching NeRF onto our shaders, as a proof of concept, we will run NeRF as a separate process on the framebuffer of the game, running entirely separately as to avoid the problem of injecting even more DLL's into the games files. Even if the rendering times for LeRF / NeRF are significantly longer than what's required for a game, we should be alright since they are running semi-independently.


# Goals and Deliverables
- What we're trying to accomplish:
  - We are 
- What results we're going for:
    - 
- Why we think we can accomplish these goals:
    - 
    - There is existing documentation and tutorials on how to inject shaders 
- Answering questions mentioned: - Since this is a graphics class you will likely define the kind of images you will create (e.g. including a photo of a new lighting effect you will simulate).
- If you are working on an interactive system, describe what demo you will create.
- Define how you will measure the quality / performance of your system (e.g. graphs showing speedup, or quantifying accuracy).
- What questions do you plan to answer with your analysis?
- In (1), describe what you believe you must accomplish to have a successful project and achieve the grade you expect (i.e. your baseline plan – planning for some unexpected problems would make sense)
    - We should be able to apply shaders to Genshin
- In (2), describe what you hope to achieve if things go well and you get ahead of schedule (your aspirational plan).
    - We hope to implement LeRF alongside the shaders. The source code for LeRF is not readily avaialable on nerfstudio.


# Schedule
- Week 1 (week of 04/03/2023 to 04/10/2023):
  - **Finish the Shaders**: be able to have various custom shaders
- Week 2 (04/10/2023)
  - **Apply Shaders to Genshin**: Work on injecting shaders to a real game engine
  - Prepare a script for the Milestone Video
  - Start working on the Milestone Status Report Webpage
- Week 3 (04/17/2023)
  - Work on LERF integration
  - Record the Milestone Video
  - Finish and submit the Milestone Status Report Webpage
  - Make initial presentation draft
- Week 4 (04/24/2023)
  - Give final presentation
  - Fill out [Peer Reviews](https://forms.gle/3HUE1mw6CSf8JkJY8).


# Resources
<!-- Pls put a line between citations -->
[This is how we will inject Shaders into Genshin Impact](https://github.com/sefinek24/Genshin-Impact-ReShade)

[LeRF](https://www.lerf.io/)


