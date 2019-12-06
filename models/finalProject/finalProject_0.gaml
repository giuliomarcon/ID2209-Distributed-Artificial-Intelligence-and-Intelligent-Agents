/***
* Name: finalProject0
* Author: Nico Catalano
* Description: 	wehfw	f�wf
* Tags: Tag1, Tag2, TagN
***/

model finalProject0


global {
	int doorSize<-6;
	
	point StageLocation <- {85,85};
	point EntranceLocation <-{doorSize/2,doorSize/2};
	point ExitLocation <-{100-doorSize/2,doorSize/2};
	
	point ChillLocation <- {15,85};
	point BarLocation <- {50,50};
	point securityLocation <- {3,50};
	
	
	init{
		create Entrance number: 1{
			location <-EntranceLocation;
		}
		
		create Exit number: 1{
			location <- ExitLocation;
		}
		
		create Stage number: 1 {
				location <- StageLocation;
		}
		create ChillArea number: 1 {
				location <- ChillLocation;
		}
		create Bar number: 1 {
				location <- BarLocation;
		}
		
		create ChillGuest number: 1{
				location <- {rnd(50-10,50+10),rnd(50-10,50+10)};
		}
		create PartyGuest number: 0 {
				location <- {rnd(50-10,50+10),rnd(50-10,50+10)};
		}
		create Security number: 1 {
				location <- securityLocation;
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
		do start_conversation to: list(Bar) protocol: 'fipa-contract-net' performative: 'cfp' contents: ['1'] ;
		
		thirsty<-0.0;
		write name+ "ask the menu:"+thirsty color:#blue;
	}
	
	reflex receivedMenu when:!empty(proposes) {
		message m <- proposes[0];
		list<string> menu <- (m.contents);
		
		int numElem <- length(menu);
		int selectedItem <- rnd(0,numElem-1);
		
		
		write name+"got menu:"+m.contents color:#purple;
		write name+"Selected:"+selectedItem color:#purple;
		
		do accept_proposal message:m contents: [selectedItem];
	}	
	

//	reflex logMessages {
//		loop c over:conversations{
//			write "conversation with:"+c;
//		}
//		loop m over:mailbox{
//			write "meesage::"+m;
//		}
//		write "proposes length:"+length(proposes) color:#pink;
//		write "is proposes not empty?:"+!empty(proposes) color:#pink;
//		
//		
//	}
	reflex selectBeverage when:!empty(informs){
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
	
	reflex provideMenu when:!empty(cfps){
		message m<-cfps[0];
		write name+" message m sender:"+m color:#orange;
		do reply message:m performative:"propose" contents:beverages;
		write name+" got asked the menu! providing:"+beverages color:#orange;
	}
	
	reflex serveDrink when:!empty(accept_proposals){
		message m <- accept_proposals[0];
		do inform message:m contents:[alchoolPercentage[int(m.contents[0])]];
	}
	aspect default{
		draw box(width, length, height) at: location color: myColor;
	}
}

species Security skills:[moving, fipa]{
	rgb myColor <- #red;
	Guest target <- nil;
	
	reflex changeColor{
		if myColor = #red {
			myColor<-#blue;
		}else{
			myColor <-#red;
		}
	}
	
	reflex initialPosition when: target=nil {
		do goto target: {3,50};
	}
	
	reflex kickOff when:target != nil and location distance_to(target) < 1 {
		
		ask target{
			//do die;
			busy<-true;
			targetPoint<-ExitLocation;
		}
	}
	reflex arriveToExit when: location distance_to(ExitLocation) < 9 {
		target<-nil;
		
	}
	reflex moveToTarget when: target != nil {
		do goto target:target;
	}
	
	aspect default{
		draw sphere(1.5) at:location color: myColor;
	}
	
}

species Entrance{
	
	aspect default{
		draw square(doorSize) at: location color: #green;
	}
}

species Exit{
	
	aspect default{
		draw square(doorSize) at: location color: #red;
	}
}


experiment Festival type: gui {
	output {
		display map type: opengl {
			species Entrance;
			species Exit;

			species Stage;
			species ChillArea;
			species Bar;
			
			species ChillGuest;
			species PartyGuest;
			species Security;
		}
	}
}
