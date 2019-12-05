/***
* Name: finalProject0
* Author: Nico Catalano
* Description: 	wehfw	f�wf
* Tags: Tag1, Tag2, TagN
***/

model finalProject0


global {
	point StageLocation <- {85,85};
	point ChillLocation <- {15,85};
	point BarLocation <- {50,50};
	
	init{
		create Stage number: 1 {
				location <- StageLocation;
		}
		create ChillArea number: 1 {
				location <- ChillLocation;
		}
		create Bar number: 1 {
				location <- BarLocation;
		}
		
		create ChillGuest number: 5 {
				location <- {rnd(50-10,50+10),rnd(50-10,50+10)};
		}
		create PartyGuest number: 5 {
				location <- {rnd(50-10,50+10),rnd(50-10,50+10)};
		}
		
	}
	
}

species Guest  skills:[moving,fipa]{
	rgb guestColor <- #red;	
	point targetPoint <- nil;
	bool busy <- false;
	
	// Treats
	float drankness <- 0.0;
	float talkative <- 0.0;
	float thirsty <- 0.0;
	float chill2dance <- 0.0;
	
	float danceTrashold <- 0.5;
	float thirstyTrashold <- 1.0;

	
	reflex moveToTarget when: targetPoint != nil {
		do goto target:targetPoint;
	}
	
	reflex updateThirsty when:thirsty<thirstyTrashold {
		//if (flip (0.1) = true){
		if(true){
			thirsty <- thirsty + rnd(0.0, 0.01);
			//write name+ "thirsty:"+thirsty;
		}
	}
	
	reflex askMenuBar when:thirsty>=thirstyTrashold and location distance_to(BarLocation) < 0.5{
		do start_conversation to: list(Bar) protocol: 'fipa-contract-net' performative: 'query' contents: [] ;
		
		thirsty<-0.0;
		write name+ "ask the menu:"+thirsty color:#blue;
	}
	
	reflex selectBeverage when:!empty(informs){
		message m <- informs[0];
		int numElem <- length(m.contents);
		int selectedItem <- rnd(0,numElem);
		
		write name+"got menu:"+m.contents;
		
		do request message:m contents: [selectedItem];
	}	
	
	reflex selectBeverage when:!empty(agrees){
		message m <- informs[0];
		float alchoolIncrement <- float(m.contents[0]);
		
		drankness<- drankness+alchoolIncrement;
	}
	
	reflex imDrunk when:drankness>=1{
		write name+"sono sbronzo!" color:#red;
	}
	
	reflex arrived2location when: targetPoint!= nil and location distance_to(targetPoint) < 1{
		busy<-false;
		targetPoint<-nil;
	}
	
	reflex dance when: busy=false{
		if (flip (chill2dance) = true){
			do wander;
		}
	}
	
    reflex goToStage when:chill2dance>= danceTrashold  and location distance_to(StageLocation) > 5 {
    	busy <- true;
    	targetPoint<-StageLocation;
    }    
    
    reflex goToChill when:chill2dance< danceTrashold  and location distance_to(ChillLocation) > 5{
    	busy <- true;
    	targetPoint<-ChillLocation;
    }    
    
    reflex goToBar when:thirsty>= thirstyTrashold {
    	busy <- true;
    	targetPoint<-BarLocation;
    }
    
    
    aspect default{
       	draw cone3D(1.3,2.3) at: location color: #slategray ;
    	draw sphere(0.7) at: location + {0, 0, 2} color: #salmon ;
    }
    
    	
} 

species ChillGuest parent: Guest{
	init{
		talkative <- rnd(0.0,1.0);
		chill2dance <- rnd(0.0,0.3);
	}
	
   	aspect default{
       	draw cone3D(1.3,2.3) at: location color: #slategray ;
    	draw sphere(0.7) at: location + {0, 0, 2} color: #blue ;
    }
}

species PartyGuest parent: Guest{
	init{
		talkative <- rnd(0.0,1.0);
		chill2dance <- rnd(0.4,1.0);
	}
	
   aspect default{
       	draw cone3D(1.3,2.3) at: location color: #slategray ;
    	draw sphere(0.7) at: location + {0, 0, 2} color: #red ;
    }
}


species Stage{	
	rgb myColor <- #red;
	
	reflex changeColor {
		myColor <- flip(0.5) ? rnd_color(100, 200) : rnd_color(100, 200);
	}
	
	aspect default{
		draw square(30) at: location color: myColor;
	}
}

species ChillArea{	
	rgb myColor <- #lightseagreen;
	
	aspect default{
		draw square(30) at: location color: myColor;
	}
}

species Bar skills:[fipa]{
	rgb myColor <- #greenyellow;
	int width <- 20;
	int length <- 10;
	int height <- 10;
	
	list<string> beverages  		<- ['Grappa', 'Montenegro', 'Beer', 'Wine','Soda', 'Cola', 'Juice', 'Julmust'];
	list<float> alchoolPercentage 	<- [	0.4, 	0.23, 		0.05, 	0.12,	0.0, 	0.0, 	0.0, 	0.0];
	
	reflex provideMenu when:!empty(queries){
		message m<-queries[0];
		write name+" got asked the menu!" color:#orange;
		do inform message:m contents:[beverages];
	}
	
	reflex serveDrink when:!empty(requests){
		message m <- requests[0];
		do agree message:m contents:[alchoolPercentage[int(m.contents[0])]];
	}
	aspect default{
		draw box(width, length, height) at: location color: myColor;
	}
}


experiment Festival type: gui {
	output {
		display map type: opengl {
			species Stage;
			species ChillArea;
			species Bar;
			
			species ChillGuest;
			species PartyGuest;

		}
	}
}
