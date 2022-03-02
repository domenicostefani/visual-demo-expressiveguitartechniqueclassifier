# Visual Demo - Expressive Guitar Technique classifier

Simple visual demo of the _Expressive Guitar Technique classifier_, coded in Processing.  

![Screen Capture of the generated visuals](https://github.com/domenicostefani/guitar-visuals/blob/main/docs/images/expressive-guitar-technique-visuals.gif)

The _Expressive Guitar Technique Classifier_ is a deep learning algorithm that can classify the expressive technique used by a guitarist.
Such classifier was developed to work on an embedded system (running ElkOS) and produce a prediction of the technique used with a maximum latency of 20ms from each individual note.  

The recognition information can be used in real-time to either trigger/modify syntetic sounds, prerecorded audio samples, control stage lighting, fog machines, video transitions and more:  
This repo contains the code that creates simple visuals which can demonstrate the potential of the system.  

Depending on the technique predicted by the classifier (from 0 to 8), the visual will change color and speed up.

The sketch receives OSC messages like the following:  
`/guitarClassifier/class i <predicted_technique[0-7]>`,  
`/guitarClassifier/class if <predicted_technique[0-7]> <confidence>`,  
or  
`/guitarClassifier/class ffffffff <conf.class0> <conf.class1> <conf.class2> <conf.class3> <conf.class4> <conf.class5> <conf.class6> <conf.class7> `  


![Architecture Diagram of the Technique Classifier](https://github.com/domenicostefani/guitar-visuals/blob/main/docs/images/architecture-diagram.png)


Inspired by [basboy12's Processing_audio_visualizer](https://github.com/basboy12/Processing_audio_visualizer).  
Domenico Stefani (domenico.stefani@unitn.it)
