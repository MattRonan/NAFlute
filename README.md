# NAFlute

![fluteRender](https://github.com/user-attachments/assets/8837680b-3b3e-4e47-847d-31aa2fe8afaa)

Native American (NAF) flutes are one of the easiest and nicest sounding instruments to play.
This customizeable Processing sketch generates the G-Code for routing a NAF flute with a base note of C#4:

![G-Code visualization](https://github.com/user-attachments/assets/b3ea667f-1951-42ed-960f-1ad3df38e057)


NAF flute design is generally very acessible, but deep.  For a more in-depth discussion check out places like 
[flutopedia](https://www.flutopedia.com/anatomy.html) or other such sources.
I'll swipe just this one diagram from them for the sake of establishing some basic terminology:

![FPanatomy_partsIN_RGB_080dpi_dswhite_c00s00](https://github.com/user-attachments/assets/e83d5a12-573f-4752-aab6-52c4c656f408)

This side-view diagram show how breath passes thru the breath hole into the Slow Air Chamber (SAC) before passing up thru a small hole
into a flat channel and passing across a hole called the fipple.  [This](https://www.flutopedia.com/fipple.htm) is a very clear side view of the
fipple shape.  Sound is then produced in the sound chamber and modified by covering or opening the 6 finger holes.

  The Processing sketch allows you to dictate all the required paramters to create a flute in the key of your choosing.  Finger hole placements, internal bore, and resonating chamber length are the main values involved in customizing the pitch.  Parameters associated with the SAC, breath hole, fipple placement,
or in other words everthing north of the fipple hole, probably don't have a major impact on the sound from my experiences.

The generated G-Code will result in the design seen in the very first picture of the readme, which is most of the battle but requires hand finishing to carve the fipple track and fipple itself, calibrate the finger holes, etc.  More detailed instructions are in the 'notes' section of the Processing sketch.

Fipple close up:
![fipple](https://github.com/user-attachments/assets/6a0692e4-2de9-433e-9958-26669322b8a2)
