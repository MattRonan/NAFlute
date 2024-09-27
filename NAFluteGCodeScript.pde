/****DISCLAIMER
*  Do not run any of the G-Code output by this sketch without fully checking and verifying that it's correct for your machine.
*  Among other things, be certain of your stock thickness, feeds/speeds, tool diameter, and always check required XYZ travels of G-code before running.
*  Author not responsible for any injury or damage resulting from use of this sketch.
*  
*  Matt Ronan 2021
*  
*/

/*----------------------------------------------NOTES

- Bore notes
   
   Bore diameter conversion: .75" = 19.05mm  1" = 25.4mm   1.25" = 31.75mm   1.5" = 38.1mm
   
   The exact bore you should use depends on the flute key.  By default this sketch is set up to make a C#4 flute with a 30mm bore (just shy of 1.25"), recommended for D#-C#4. 
   The bore impacts resonance, but I don't doubt that you could use the same bore for a higher or lower flute.  This page has a detailed chart: https://www.flutopedia.com/faq_craft.htm
   Flute is about 550mm long with a good balance of low and high range.  
   The key and bore size were specifically selected for ease of construction using 3/4" stock which is readily available at big box hardware stores.
   Total default flute thickness is 38mm and with a 30mm bore size you are automatically set up for 4mm walls.
   Obviously, you can do smaller bores and face down the stock to dial in the bottom wall's thickness, but its quicker to just work with what's readily available.
   
   
- Finishing the flute
    
    The machine will do almost everything, but some hand work needs to be done to finish it up.
    For the first 2 steps, leave the 2 halves connected with the tabs, because for milling the flue you'll likely want to strap it back onto the cnc table.
    
    1) Drilling the ramp.  This is an angled tunnel that connects the slow air chamber to the flue.  The topmost hole on the flute is placed so that you can take a hand drill
       and **FROM THE OUTSIDE** drill down into the slow air chamber at an angle.  This angle is probably about 20 30 degrees off of straight down; see fluetopedia for a side view diagram if needed.
       It needn't be anything super exact, just angled to help guide the air up into the flue.  To avoid blowout, start with a 1/8" bit and work up to 1/4".  A stepper bit can help.
       Drilling from outside in is crucial because you need the 2 outside holes to be perfectly in line for milling the flue.
    2) Milling the flue.  This can be done completely by hand, but I think the easiest way is to flip the workpiece and bolt it back onto the table, being careful to line up the 2 top air holes
       to be perfectly in line with the X axis of the machine.  Now simply jog the bit around between the 2 holes to create a flat 1/4" wide track about 1mm deep connecting them.
    3) Squaring the flue holes.  At this point the 2 halves can be separated if you want.  Use a 1/4" metal file to make each of the 2 round flue holes square.  Flue
       should now be 2 1/4"x1/4" square holes conntected by a 1mm deep 1/4" track.
    4) File the splitting edge.  Very simple but difficult to explain in text, see pictures on github or flutopedia.com. 
    5) Glue 2 halves together.
    6) Make a 'bird' to tie onto the flue track.  Can be a simple block of wood, though it traditionally is a carving.  This forms the ceiling of the flue to aim a ribbon of air at the splitting edge.
       Experiment with position as this will impact the quality and intonation of the sound.
    7) Fine tune holes for best possible intonation.  This is a craft which is best learned via resources like https://flutecraft.org/how-to-tune-native-american-flute-part-3/174
       That being said, the flute should be playable as is, if not a bit wiley.
 
  */

//****most important user values
float stockThickness = 19;  //thickness of the board
float toolD = 3.0; //tool diameter.  3mm flat endmill bit was used in developing this sketch
int highSpeed = 650;
int normalSpeed = 500;
int lowSpeed = 300;
int plungeSpeed = 50;
//*******end most important user values

float fippleHoleXPos = 109;
float fingerHoleOffset = 138.5; //distance from center of fipple hole to center of first finger hole.  
float fingerHoles[] =  {0,23,48,     //(indexed from fippleHoleXPos+fingerHoleOffset, so if fippleHoleXPos=109, fingerHoleOffset=138.5, first finger hole is at 247.5mm from the top edge of the flute
                        101,137,166};//These 6 hole positions worked on the default C# flute.  To change them for a different length/pitch/bore flute, you'll have to experiment.  
                                     
float blowHoleLength = 25; //about 1"
float slowAirChamberLength = 55; //about 2" 
float woodBlockLength = 28.5; //aboiut 1.125"
float blowHoleBore = 9.5; //3/8"
float boreSize = 30; 
float slowAirChamberBore = 24; //this often looks slightly smaller than the bore in some pics of seen
float mainChamberLength = 429;//this is the total cylindrical section of the bore. Doesnt include the quarter sphere part at the top.
float wallThickness = 4;   
float totalLength = blowHoleLength + slowAirChamberLength + slowAirChamberBore + mainChamberLength + (boreSize/2);

float toolR = toolD/2; 

int procedure = 0; 

float xOff = 0; //x/y offset in view window
float yOff = 0;
float xCoord,yCoord;
float hyp;
float theta;
float a,b;

float tabSize = 0;
float stepover = 0;
float zO = 0;

void setup(){
  size(500, 500);
  ellipseMode(CENTER);
  noLoop();
  background(0);
}

OutputFile F = new OutputFile(100000);

void draw(){
  
  for(int p = 0; p <= 0; p++){
  
   
       /* Procedure 0, entire flute.
        ██████  ██████   ██████   ██████ ███████ ██████  ██    ██ ██████  ███████      ██████      
        ██   ██ ██   ██ ██    ██ ██      ██      ██   ██ ██    ██ ██   ██ ██          ██  ████   
        ██████  ██████  ██    ██ ██      █████   ██   ██ ██    ██ ██████  █████       ██ ██ ██    
        ██      ██   ██ ██    ██ ██      ██      ██   ██ ██    ██ ██   ██ ██          ████  ██    
        ██      ██   ██  ██████   ██████ ███████ ██████   ██████  ██   ██ ███████      ██████    
          */
                                                                                     
     if(p == 0){
       
       F.plus("Flute job.  Stock should be " + stockThickness + " mm");
       F.plus("Tool diameter: " + (toolD) + " mm");
       
       F.plus("G17 G21 G90 G94 G40");
       F.plus("M05");
       F.plus("F" + normalSpeed+" S1000");
       F.plus("M03");
       F.plus("G00 Z2");
       F.plus("G00 X0 Y0");
      //hey add drill fipple hole at X=109mm, and mark SAC side hole at X = 68
       
        F.plus("G00 Z2");
       
     int scoopRez = 3;
     
     xOff = 0;
     yOff = boreSize/-2;

        tabSize = 0;

        for(int h = 0; h < 2; h++){
      
            //*******blowhole
            scoop((blowHoleBore/2),0,scoopRez,xOff,yOff+(boreSize/2)-(blowHoleBore/2),0,blowHoleLength,1,normalSpeed,highSpeed,0);
            xOff+= blowHoleLength;
            F.plus("G00 Z2");
            
            //******slow air chamber
            xOff+= (slowAirChamberBore/2)-toolR;
            dome((slowAirChamberBore/2),0,360,360,scoopRez,xOff-(slowAirChamberBore/2),yOff+(boreSize/2)-(slowAirChamberBore/2),0,1,false,normalSpeed,1);//actual dome
             F.plus("G00 Z2");
            dome((slowAirChamberBore/2),0,360,360,scoopRez,xOff+slowAirChamberLength-(slowAirChamberBore)-(slowAirChamberBore/2),yOff+(boreSize/2)-(slowAirChamberBore/2),0,1,false,normalSpeed,1); //dome
             F.plus("G00 Z2");
            scoop((slowAirChamberBore/2),0,scoopRez,xOff,yOff+(boreSize/2)-(slowAirChamberBore/2),0,slowAirChamberLength-slowAirChamberBore,1,normalSpeed,highSpeed,0);
             F.plus("G00 Z2");
            xOff+= slowAirChamberLength;
            
            //*******skip some for the wood block section
            xOff += woodBlockLength;
        
            //*******main shaft
             F.plus("G00 Z2");
            dome((boreSize/2),0,360,360,scoopRez,xOff-(boreSize/2),yOff+(boreSize/2)-(boreSize/2),0,1,false,normalSpeed,1);
            F.plus("G00 Z2");
            scoop((boreSize/2),0,scoopRez,xOff,yOff,0,mainChamberLength,1,normalSpeed,highSpeed,0); 
            
            F.plus("G00 Z2");
            
            //*****************mark hole for air ramp out of SAC
            drillHole(68,0,((boreSize/2)+.5)*-1,75); 
            F.plus("G00 Z2");
            
            //***********drill fipple hole all the way thru
            drillHole(fippleHoleXPos,0,(stockThickness+.5)*-1,75); 
            F.plus("G00 Z2");
            
            //***********finger holes.  (more complicated if doing the flute in 2 separate jobs but this assumes a bigger machine and a single job)
            for(int fH = 0; fH < 6; fH++){
              drillHole(fippleHoleXPos+fingerHoleOffset+fingerHoles[fH],0,(stockThickness+.5)*-1,75); 
              F.plus("G00 Z2");
            }
            
          yOff += (boreSize)+(wallThickness*2)+(toolR*2);
          xOff = 0;
          
          F.plus("G00 Z2");
        }
        
        float ltd = (stockThickness-1.5)*-1; //longTabDepth
        float z;
        float stepover = 0;
 
        
        //outline front half
         F.plus("G00 Z2");
         //ouctline
         for(z = 0; z >= (stockThickness+.5)*-1; z -= .5){
           if(z < (stockThickness - 2) * -1){
             tabSize = 10; 
             stepover = 2;
           }
           else{
             tabSize = 0; 
             stepover = 0;
           }
           cutRectangle(1,0,0,-1*(boreSize+(wallThickness*2))/2, z,totalLength, boreSize+(wallThickness*2),toolR,tabSize,stepover,60.0);
         }
        
         
         //outline back half
         F.plus("G00 Z2");
         //ouctline
         for(z = 0; z >= (stockThickness+.5)*-1; z -= .5){
           if(z < (stockThickness - 2) * -1){
             tabSize = 10; 
             stepover = 2;
           }
           else{
             tabSize = 0; 
             stepover = 0;
           }
           cutRectangle(1,0,0,((boreSize+(wallThickness*2))/2)+(toolR*2), z,totalLength, boreSize+(wallThickness*2),toolR,tabSize,stepover,60.0);
         }
        F.plus("G00 Z2");
        
     }
                                                                                      
     F.plus("G00 Z2");
     F.plus("M05");
     F.plus("M02");
          
     F.export("naFlute" + p +".nc");
     
     println("exported naFlute"+p+".nc to sketch folder"); 
     
     //procedure++;
     F.reset();
  }
}

void drillHole(float x, float y, float zee, float plungeSpee){
 
       for(float z = 0; z >= zee; z -= .5){
           F.plus("F300");
              F.plus("G01 X" + (x) + " Y" + (y));
              F.plus("F" + plungeSpee);
           F.plus("G01 Z" + z);
           F.plus("G01 Z" + (z+1));
         }
         
         F.plus("G00 Z2");
}

void cutCustomSilhouette(int inOut, float xOff, float yOff, float[][] points,int[] tabs, float z,float tabSize, float stepover){

   //this is outdated but I'm leving it as a referene for tabs on an arbitrary 2D profile
   float mod;
   
   if(inOut == 0){
     mod = (toolR * -1); 
   }
   else if(inOut == 1){
     mod = toolR; 
   }
   else{
     
     mod = 0; 
   }
  
   F.plus("300");
   F.plus("G00 X"+ (points[0][0]+xOff) + "Y" + (points[0][1]+yOff)); //make sure we're at the first point before cutting in
    
  
       for(int i = 0; i < points.length-1; i++){
         
         F.plus("G01 Z"+z);
         F.plus("G01 X"+ (points[i][0]+xOff) + "Y" + (points[i][1]+yOff));
         
         if(tabSize > 0){
           if(tabs[i] == 1){//if theres a tab indicated here go over,up,over,down, and then over to the next point.  then manually increment i cause the next loop cycle would be redundant
             
             int next;                                                                                                                                  
             
             if(i == points.length){
                next = 0;
             }
             else{
               next = i+1; 
             }
             
             a = (points[next][0]-points[i][0]);
             b = (points[next][1]-points[i][1]);
             hyp = sqrt(pow(a,2) + pow(b,2));
             theta = atan(b/a);
             
             if(points[i+1][0] < points[i][0]){ 
                theta += PI;
             }
             
             //this is overkill if your lines are all all horizontal or vertical, but it works for any sloped line. ze() is because things sometimes read 5.682E-7 etc, which is just 0 but Gcode cant interpret that
             F.plus("G01 X"+ (ze((points[i][0] + (((hyp/2)-(hyp*tabSize/2))*cos(theta))))+xOff) + "Y" + (ze((points[i][1] + (((hyp/2)-(hyp*tabSize/2))*sin(theta)))) + yOff) );//over
             F.plus("G01 Z" + (z+2));//up
             F.plus("G01 X"+ (ze((points[i][0] + (((hyp/2)+(hyp*tabSize/2))*cos(theta)))) + xOff) + "Y" + (ze((points[i][1] + (((hyp/2)+(hyp*tabSize/2))*sin(theta)))) + yOff) );//over
             F.plus("G01 Z"+z);//down
             F.plus("G01 X"+ (points[next][0] + xOff) + "Y" + (points[next][1] + yOff));//next point
             
             
           }  
         }
       }
   
   F.plus("G01 X"+ (points[0][0] + xOff) + "Y" + (points[0][1] + yOff));//return to start to finish shape
  
}


void scoop(float shaftR,int cornOrCent, int drillInc,float scoopX,float scoopY,float zOff,float scoopHeight, int scoopDirection,int scooSpee, int cleanSpee,int cleanMod){

      // drillInc  is basically degrees.  So the lower this number, the more rounded the result, the higher the number the more boxy
      float[][] scoop = new float[2][(180/drillInc) + 1];  //since we're carving a scoop into the z axis, this is an array of (x,z) coords.  Y is just where we position the scoop on the y axis
  
      // Calculate RAW scoop coords, no x/y or cutter offsets.  The scoop shape to be moved where we want.
      int indexCounter = 0;
      for(int i = 180; i >= 0; i -= drillInc){
        float c1 = cos(radians(i)); //coordinate1 and coord2. c2 is always z, but c1 could refer to x or y depending on what direction the scoop is directed
        float c2 = sin(radians(i));
        c1 = ze((c1*shaftR)+shaftR);//shaftR is the wooden bead shaft 
        c2 = ze((c2*shaftR*-1)); //Z axis is reversed in processing compared to real life so -1 flips it back.
        scoop[0][indexCounter] = c1; scoop[1][indexCounter] = c2; //saving them in an array too cause why not
        indexCounter++;
        
      }
    
      int centerPoint = 180/drillInc/2;
      int LT,RT;
     
      //-----------------------------------------------------------PHASE 1: ARC CARVING
        
          float currentOffset = (toolR*2)*-1; //this is just so that we can bail out of the loop when currentY==scoopY, but only AFTER we USE currentOffset, meaning we need
                                               //to increment it at the BEGINNING of each loop, which means for currentOffset to start at 0, it needs to be initialized negative so that the first
                                                 //increment brings it to 0.  Just something I'm trying.
          
          
          
          while(currentOffset != scoopHeight){
            
            currentOffset += (toolR*2);
            
            if(currentOffset > scoopHeight){ currentOffset = scoopHeight;}
            
            //braindead way of changing scoop direction.  But I don't need anything more right now so we.
            
            if(scoopDirection == 0){
              F.plus("G00 Z" + (zOff+1));//protective retraction for bit.
              F.plus("G01 Y" + (scoopY + currentOffset));
              LT = 0;
              RT = 180 / drillInc;
                  
              while(LT+2 < centerPoint){  
                F.plus("F" + scooSpee);
                F.plus("X" + ze( scoop[0][LT]+toolR+scoopX)); //LEFT push forward bit to align with next depth coord. //once this line puts us at the center point, we just have to drill straight down to finish
                F.plus("F" + plungeSpeed);
                F.plus("Z" + ze(scoop[1][LT+1] + zOff)); //LEFT drill down to next depth coord
                F.plus("F" + scooSpee);
                F.plus("X" + ze(scoop[0][RT]-toolR+scoopX));//CROSS carve over to opposite sid
                F.plus("X" + ze(scoop[0][RT-1]-toolR+scoopX)); //RIGHT. return a tad to the left to align with next point
                F.plus("F" + plungeSpeed);
                F.plus("Z" + ze(scoop[1][RT-2] + zOff) ); //RIGHT drill to next depth coord
                F.plus("F" + scooSpee);
                F.plus("X" + ze(scoop[0][LT+1]+toolR+scoopX)); //CROSS carve over to opposite side
                LT+=2; RT-=2;
                
                if(abs(scoop[0][LT] - scoop[0][RT]) <= (toolR*2)){
                  break; 
                }
                
              }
              
              //we're left at point to left of center, move to center and drill final depth coord.
              F.plus("X" + ze(scoop[0][centerPoint]+scoopX)); //note no more offset.
              F.plus("F" + plungeSpeed);
              F.plus("Z" + ze(scoop[1][centerPoint] + zOff)); 
            }
            else{
              F.plus("G00 Z" + ze(zOff+1));//protective retraction for bit.
              F.plus("G01 X" + ze(scoopX + currentOffset));
              LT = 0;
              RT = 180 / drillInc;
                  
              while(LT+2 < centerPoint){    
                 F.plus("F" + scooSpee);
                F.plus("Y" + ze( scoop[0][LT]+toolR+scoopY)); //LEFT push forward bit to align with next depth coord. //once this line puts us at the center point, we just have to drill straight down to finish
                F.plus("F" + plungeSpeed);
                F.plus("Z" + ze(scoop[1][LT+1] + zOff)); //LEFT drill down to next depth coord
                F.plus("F" + scooSpee);
                F.plus("Y" + ze(scoop[0][RT]-toolR+scoopY));//CROSS carve over to opposite sid
                F.plus("Y" + ze(scoop[0][RT-1]-toolR+scoopY)); //RIGHT. return a tad to the left to align with next point
                F.plus("F" + plungeSpeed);
                F.plus("Z" + ze(scoop[1][RT-2] + zOff) ); //RIGHT drill to next depth coord
                F.plus("F" + scooSpee);
                F.plus("Y" + ze(scoop[0][LT+1]+toolR+scoopY)); //CROSS carve over to opposite side
                
                if(abs(scoop[0][centerPoint] - scoop[0][LT]) < toolR ){
                  break; 
                }
                
                LT+=2; RT-=2;
              }
              
              //we're left at point to left of center, move to center and drill final depth coord.
              F.plus("F" + scooSpee);
              F.plus("Y" + ze(scoop[0][centerPoint]+scoopY)); //note no more offset.
              F.plus("F" + plungeSpeed);
              F.plus("Z" + ze(scoop[1][centerPoint] + zOff)); 
            }
          F.plus("F" + scooSpee);
          }
          F.plus("G00 Z1");//protective retraction 
          
            
        //---------------------------------------------------------------PHASE 2: CARVE AROUND PERIMETER
        
        // Could just be a second method.  Basically for big scoops we may want a cleaning pass thats even more fine resolution than the scoop outline.  
        //this is defined by subtracting cleanMod from drillInc.  So to have both scoop and cleaning pass be the same, pass in 0 for cleanMod.  But to clean at finer resolution, pass in a negative number.
        //-1 is probably all you need.  On a 28mm bore, a drillInc of 3 leaves minor but clear stair steps.  I think with a cleanMod of -1 ie a cleaing drillInc of 2, I think we'll erase all the steps
        // Anyway in order to do that, we have to totally recalutlate the scoop coords and have a bigger scoop array that used in normal scoop block, hence the float[][]cleaner.  But cleaner[][] is the exact
        //same thing as scoop[][], it just might have more points to move thru if your cleanMod is a negative number.
        
        float[][] cleaner = new float[2][(180/drillInc) + 1];  //since we're carving a scoop into the z axis, this is an array of (x,z) coords.  Y is just where we position the scoop on the y axis
  
        
       indexCounter = 0;
      for(int i = 180; i >= 0; i -= drillInc){
        float c1 = cos(radians(i)); //coordinate1 and coord2. c2 is always z, but c1 could refer to x or y depending on what direction the scoop is directed
        float c2 = sin(radians(i));
        c1 = ze((c1*shaftR)+shaftR);//shaftR is the wooden bead shaft 
        c2 = ze((c2*shaftR*-1)); //Z axis is reversed in processing compared to real life so -1 flips it back.
        cleaner[0][indexCounter] = c1; cleaner[1][indexCounter] = c2; //saving them in an array too cause why not
        indexCounter++;
        
      }
    
      centerPoint = 180/drillInc/2;
      
        
        
        LT = 0;
        RT = 180/drillInc;
        
        F.plus("G00 Z1");//protective retraction.
        F.plus("M03");
        F.plus("G01");
         
        if(scoopDirection == 0){
          
          
        }
        else if(scoopDirection == 1){
       
          while(LT != RT){
            F.plus("F" + cleanSpee);
            F.plus("Y" + (cleaner[0][LT]+toolR+scoopY) );
            F.plus("F" + plungeSpeed);
            F.plus("Z" + (cleaner[1][LT+1]) );
            F.plus("F" + cleanSpee);
            F.plus("Y" + (cleaner[0][RT]-toolR+scoopY) );
            F.plus("X" + (scoopHeight-toolR + scoopX) );
            F.plus("Y" + (cleaner[0][LT]+toolR+scoopY) );
            F.plus("X" + scoopX);
            
            if(abs(cleaner[0][LT] - cleaner[0][RT]) <= (toolR*2)){
                  break; 
                }
            LT++;RT--;
          }
        }
        
}

void dome(float shaftR, int cornOrCent, int star, int en, int drillInc,float domeX,float domeY,float zOff, int invert,boolean cleaner,int speed,float zScale){

  
      //dome calculates points from bottom left corner.  So for centering it, we change the xy offset.
      if(cornOrCent == 1){
        domeX -= shaftR;
        domeY -= shaftR;
      }
  
      // drillInc  is basically degrees.  So the lower this number, the more rounded the result, the higher the number the more boxy
      float[][] scoop = new float[2][(90/drillInc) + 1];  //since we're carving a scoop into the z axis, this is an array of (x,z) coords.  Y is just where we position the scoop on the y axis
  
      // Calculate RAW scoop multipliers, no x/y, scale, or cutter offsets.  The scoop shape to be moved where we want.
      int indexCounter = 0;
      for(int i = 90; i >= 0; i -= drillInc){
        float r = cos(radians(i))*-1; //coordinate1 and coord2. c2 is always z, but c1 could refer to x or y depending on what direction the scoop is directed
        float c2 = sin(radians(i));
        
        if(invert == 1){ c2 *= -1; }
        
        c2*=zScale;
        
        r = abs(ze((r*shaftR)));//shaftR is the wooden bead shaft 
        
        c2 = ze((c2*shaftR)); //Z axis is reversed in processing compared to real life so -1 flips it back. and the invert-1 jibberjabber is because otherwise a mountain dome (non inverted dome) will END at z=0, instead of STARTING on Z=0.
       
        if(invert == 0){ c2 -= (shaftR*zScale);}
        
        scoop[0][indexCounter] = r; scoop[1][indexCounter] = c2+zOff; //saving them in an array too cause why not
        indexCounter++;
      }
      
   
      int centerPoint = 90/drillInc/2;
      
     
       int start, end, inc;
       
       if(invert == 0){ 
         for(int i = 0; i < scoop[0].length; i++){
          
          if(cleaner){
            cutCircle(1,1,star,en,domeX+shaftR, domeY+shaftR, scoop[1][i],scoop[0][i],toolR,0, 2,speed);
          }
          else{
            circularFace(1,1,star,en,domeX+shaftR, domeY+shaftR, scoop[1][i], scoop[0][i],shaftR,toolR,0, 2,speed); //non inverted (mountain) cuts OUTSIDE the dome coords
          }
         }
       }
       else{
        for(int i = scoop[0].length-1; i >= 0; i --){
          if(scoop[0][i] <= toolR){
            break; 
          }
          if(cleaner){
            cutCircle(0,1,star,en,domeX+shaftR, domeY+shaftR, scoop[1][i], scoop[0][i],toolR,0, 2,speed);
          }
          else{
            circularFace(0,1,star,en,domeX+shaftR, domeY+shaftR, scoop[1][i], 0,scoop[0][i],toolR,0, 2,speed); //inverted dome (bowl) cuts INSIDE the dome coords
          }
        }
       }
       
      F.plus("G00 Z1");//protective retraction 
            

        
}


void cutRectangle(int inOut, int cornOrCent,float xBottomLeft, float yBottomLeft,float z, float l, float w, float toolR, float tabSize,float stepover,float tabDistance){
  
  float modX = 0;
  float modY = 0;
  float a,b,hyp,theta;
  
  if(cornOrCent == 0){//coords indicatebottom left corner, offset circle position
    
  }
  else if(cornOrCent == 1){
     xBottomLeft -= (l/2); yBottomLeft -= (w/2);
  }
  else if(cornOrCent == 2){
     //for rectangular face, its best for the main method to just tell this where to make it's bottom left corner, and not have this do anything.
     //so wether that ends up being center or corner is determined in the rectangularFace method then passed here and done in corner mode
  }
  
  //when inout is 0 we are cutting an ID rectangle.  When inout is 1 we're cutting an OD rectangle
  //retangles always start from bottom left corner.
  
   if(tabSize == 0){
     if(inOut == 0){modX = toolR;modY = toolR; }else if(inOut == 1){modX = (toolR*-1); modY = (toolR*-1);}
     F.plus("G01 X"+(xBottomLeft+modX) + " Y" + (yBottomLeft+modY));//inital positionning
     F.plus("F"+plungeSpeed);
     F.plus("G01 Z"+z);
     F.plus("F"+normalSpeed);
     if(inOut == 0){modX = toolR;modY = (toolR*-1); }else if(inOut == 1){modX = (toolR*-1); modY = (toolR);}
     F.plus("G01 X"+(xBottomLeft+modX) + " Y" + (yBottomLeft+modY+w));
     
     if(inOut == 0){modX = (toolR*-1);modY = (toolR*-1); }else if(inOut == 1){modX = (toolR); modY = (toolR);}
     F.plus("G01 X"+(xBottomLeft+modX+l) + " Y" + (yBottomLeft+modY+w));
     
     if(inOut == 0){modX = (toolR*-1);modY = toolR; }else if(inOut == 1){modX = (toolR); modY = (toolR*-1);}
     F.plus("G01 X"+(xBottomLeft+modX+l) + " Y" + (yBottomLeft+modY));
     
     if(inOut == 0){modX = toolR;modY = toolR; }else if(inOut == 1){modX = (toolR*-1); modY = (toolR*-1);}
     F.plus("G01 X"+(xBottomLeft+modX) + " Y" + (yBottomLeft+modY)); //return to start
   }
   else{
     
     //it's just easier to do this if our rectangle is defined in an array format
     float[][] points = { {xBottomLeft,yBottomLeft},
                          {xBottomLeft,yBottomLeft+w},
                          {xBottomLeft+l,yBottomLeft+w},
                          {xBottomLeft+l,yBottomLeft},
                          {xBottomLeft,yBottomLeft},
                         };

     
     float[][][] mods = {  
                           { {1,1},{1,-1},{-1,-1},{-1,1},{1,1}   },  
                           { {-1,-1},{-1,1},{1,1},{1,-1},{-1,-1} }  
                        };
     
     for(int i = 0; i < 4; i++){
       
       a = abs((points[i+1][0]+(toolR*mods[inOut][i+1][0])) - (points[i][0]+toolR*mods[inOut][i][0]));
       b = abs((points[i+1][1]+toolR*mods[inOut][i+1][1]) - (points[i][1]+toolR*mods[inOut][i][1]));
       hyp = sqrt(pow(a,2) + pow(b,2));
       theta = atan(b/a);
       
       if(points[i+1][0] < points[i][0]){ 
              theta += PI;
       }
       else if(points[i+1][1] < points[i][1]){
          theta += PI; 
       }
       
       F.plus("G01 X"+(points[i][0]+(toolR*mods[inOut][i][0])) + " Y" + (points[i][1]+toolR*mods[inOut][i][1]));//inital positioning
       F.plus("F"+plungeSpeed);
       F.plus("G01 Z"+z);
       F.plus("F"+normalSpeed);
       
       //this is where our line is broken up into tabs.  On rectangular or circular outlines this is easy.  Arbitrary silhouettes are a little more complex.
       //tabDistance will change how many tabs there are per side.
       //move to front edge of tab
       println(i + ": "+hyp); //in the case of simple square-to-the grid rectangles, hyp ends up being just the length of the current line segment.
       
       int numTabs = int(hyp/tabDistance)-1; 
       
       if(numTabs > 0){
         
         for(int tb = 1; tb <= numTabs; tb++){
           F.plus("G01 X"+ ze(((toolR*mods[inOut][i][0])+points[i][0] + ((( tb*hyp/(numTabs+1) )-(tabSize/2))*cos(theta)))) + "Y" + ze(((toolR*mods[inOut][i][1])+points[i][1] + ((tb*hyp/(numTabs+1)-(tabSize/2))*sin(theta)))));//over
           
           // step up
           F.plus("G01 Z" + (z+stepover));
           
           //move to trailing edge of tab
           F.plus("G01 X"+ ze(((toolR*mods[inOut][i][0])+points[i][0] + (((tb*hyp/(numTabs+1))+(tabSize/2))*cos(theta)))) + "Y" + ze(((toolR*mods[inOut][i][1])+points[i][1] + (((tb*hyp/(numTabs+1))+(tabSize/2))*sin(theta)))));//over
           
           //step back down
           F.plus("F"+plungeSpeed);
           F.plus("G01 Z"+z);//down
           F.plus("F"+normalSpeed);
           
           //end of tab
         }
       }
       
       F.plus("G01 X"+ ((toolR*mods[inOut][i][0])+points[i+1][0]) + "Y" + ((toolR*mods[inOut][i][1])+points[i+1][1]) );//next point
     
     }
   }
}
void circularFace(int inOut, int cornOrCent, int star, int en, float xCent,float yCent, float z, float startR, float endR, float toolR,float tabAmount,float stepover,int speed){
  
  if(startR < toolR){ startR = toolR;}
  
  float rad = startR;
  
  
  while(rad < endR){
    cutCircle(inOut, cornOrCent,star,en,xCent,yCent,z,rad,toolR,tabAmount,stepover,speed);
    rad+=(toolR*2);
  }
  
  cutCircle(inOut,cornOrCent,star,en,xCent,yCent,z,endR,toolR,tabAmount,stepover,speed);//final go-around at exactly OD, since above while loop stops short of the actual OD.
  
  
}

void cutCircle(int inOut,int cornOrCent,int star,int en,float xCent, float yCent, float z,  float r,float toolR,float tabAmount, float stepover,int speed){
  //(tab amount is in degrees)
 
  if(inOut == 0){
    r -= toolR; //if r is referring to ID, SUBTRACT toolR
  }
  else if(inOut == 1){
    r += toolR; //if r is referring to OD, ADD toolR
  }
  else{
    
  }
  
  if(cornOrCent == 0){//coords indicatebottom left corner, offset circle position
     xCent += r; yCent += r;
  }
  else if(cornOrCent == 1){
    
  }
    if(star == 360 && en == 360){ //for now any custom arcs dont work with tabs (360,360,360 is nonesense but is easy to remember for now)
      F.plus("F" + speed);
      F.plus("G01 " + "X"+fmt((cos(radians(180-tabAmount))*r) + xCent) + " Y"+ fmt((sin(radians(180-tabAmount))*r) + yCent));
      F.plus("G02 X"+fmt((cos(radians(180-tabAmount))*r) + xCent) + " Y"+ fmt((sin(radians(180-tabAmount))*r) + yCent)  + " R" + r) ;
      F.plus("F" + plungeSpeed);
      F.plus("G01 Z"+z);
      
      F.plus("F" + speed);
      F.plus("G02 " + "X"+fmt((cos(radians(90+tabAmount))*r) + xCent) + " Y"+ fmt((sin(radians(90+tabAmount))*r) + yCent) + " R" + r);
      if(tabAmount == 0){F.plus("F" + plungeSpeed); F.plus("G01 Z"+z); } 
      else{F.plus("G01 Z"+(z+stepover));}
      F.plus("F" + speed);
      F.plus("G02 " + "X"+fmt((cos(radians(90-tabAmount))*r) + xCent) + " Y"+ fmt((sin(radians(90-tabAmount))*r) + yCent) + " R" + r);
      F.plus("F" + plungeSpeed);
      F.plus("G01 Z"+z);
      F.plus("F" + speed);
      
      F.plus("G02 " + "X"+fmt((cos(radians(0+tabAmount))*r) + xCent) + " Y"+ fmt((sin(radians(0+tabAmount))*r) + yCent) + " R" + r);
      if(tabAmount == 0){F.plus("F" + plungeSpeed); F.plus("G01 Z"+z); } 
      else{F.plus("G01 Z"+(z+stepover));}
      F.plus("F" + speed);
      F.plus("G02 " + "X"+fmt((cos(radians(360-tabAmount))*r) + xCent) + " Y"+ fmt((sin(radians(360-tabAmount))*r) + yCent) + " R" + r);
      F.plus("F" + plungeSpeed);
      F.plus("G01 Z"+z);
      F.plus("F" + speed);
      
      F.plus("G02 " + "X"+fmt((cos(radians(270+tabAmount))*r) + xCent) + " Y"+ fmt((sin(radians(270+tabAmount))*r) + yCent) + " R" + r);
      if(tabAmount == 0){F.plus("F" + plungeSpeed); F.plus("G01 Z"+z); } 
      else{F.plus("G01 Z"+(z+stepover));}
      F.plus("F" + speed);
      F.plus("G02 " + "X"+fmt((cos(radians(270-tabAmount))*r) + xCent) + " Y"+ fmt((sin(radians(270-tabAmount))*r) + yCent) + " R" + r);
      F.plus("F" + plungeSpeed);
      F.plus("G01 Z"+z);
      F.plus("F" + speed);
      
      F.plus("G02 " + "X"+fmt((cos(radians(180+tabAmount))*r) + xCent) + " Y"+ fmt((sin(radians(180+tabAmount))*r) + yCent) + " R" + r);
      if(tabAmount == 0){F.plus("F" + plungeSpeed); F.plus("G01 Z"+z); } 
      else{F.plus("G01 Z"+(z+stepover));}
      F.plus("F" + speed);
    }
    else{ 
      
      F.plus("F" + speed);
      F.plus("G01 " + "X"+fmt((cos(radians(star))*r) + xCent) + " Y"+ fmt((sin(radians(star))*r) + yCent));
      F.plus("G02 X"+fmt((cos(radians(star))*r) + xCent) + " Y"+ fmt((sin(radians(star))*r) + yCent)  + " R" + r) ;
      F.plus("F" + plungeSpeed);
      F.plus("G01 Z"+z);
      
      F.plus("F" + speed);
      star-=90;
      if(star <0){ star += 360;}
      F.plus("G02 " + "X"+fmt((cos(radians(star))*r) + xCent) + " Y"+ fmt((sin(radians(star))*r) + yCent) + " R" + r);
   
      
      F.plus("G02 " + "X"+fmt((cos(radians(en))*r) + xCent) + " Y"+ fmt((sin(radians(en))*r) + yCent) + " R" + r);
      
      F.plus("G01 Z1");
      F.plus("G01 " + "X"+fmt((cos(radians(180))*r) + xCent) + " Y"+ fmt((sin(radians(180))*r) + yCent) + " R" + r);
  
      F.plus("F" + speed);
    }
}

float fmt(float n){
   return parseFloat(nf(n,0,2));
}

float ze(float in){

  if(in >= 0 && in < .01){
    return 0; 
  }
  else if(in < 0 && in > -.01) {
    return 0;
  }
  else{
    return in; 
  }
}

class OutputFile{
  
  String[] data;
  int index;
  
  public OutputFile(int s){
    data = new String[s]; 
    index = 0;
  }
  public void plus(String s){
    data[index] = s;
    index++;
  }
  public void export(String name){
    String[] output = new String[index];
    
    //otherwise the unfilled spaces in the original data array will print 'null' to the txt file.
    for(int i = 0; i < index; i++){
      output[i] = data[i];
    }
    
    saveStrings(name, output);
  }
  public void reset(){
    index = 0; 
  }
}
