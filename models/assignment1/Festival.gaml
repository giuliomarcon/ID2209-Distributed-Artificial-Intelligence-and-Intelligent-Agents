/***
* Name: Festival
* Author: giuliomarcon
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model Festival

global {
	/** Insert the global definitions, variables and actions here */
	point InformationLocation <- {30,30};
	point EnormousLocation <- {50,80};
	point EntranceLocation <-{0,0};
	point ExitLocation <-{100,100};
	int numberOfPeople <-0;
	int numberOfDealers <-0;
	
	// number of vist at each shop before quitting
	int threshold <- 100;
	
	init{
		
//		create FestivalGuest number: 10
//		{
//			location <- {rnd(0,101),rnd(0,101)};
//		}
		create Entrance number: 1{
			location <-EntranceLocation;
		}
		
		create Exit number: 1{
			location <- ExitLocation;
		}
		
		create InformationCentre number: 1{
			location <-InformationLocation;
		}
		
		create WaterFountain number: 1{
			point WaterLocation <- {90,50};
			location <-WaterLocation;
		}
		
		create FoodStand number: 1{
			point FoodLocation <- {80,10};
			location <-FoodLocation;
		}
		
		create Bathroom number: 1{
			point BathLocation <- {10,90};
			location <-BathLocation;
		}
		
		create TobaccoShop number: 1{
			point TobaccoLocation <- {42,12};
			location <-TobaccoLocation;
		}
		
		create EnormousStage number: 1 {
			location <- EnormousLocation;
		}
		
//		create Dealer number:2 {
//			location <- {rnd(30,80),rnd(60,90)};
//		}
		create Security number:1 {
			location <- {3,50};
		}
	}
	reflex spawnGuest when: numberOfPeople<20{
		create FestivalGuest number: 1{
			location <- EntranceLocation;
			busy <- true;
//			targetPoint <- {4,30};
			targetPoint<-EnormousLocation+{rnd(-20,20),rnd(10,-20)};
		}
		numberOfPeople <- numberOfPeople +1;
	}
	

	
	reflex spawnDealer when: numberOfDealers<1{
		if (flip(0.01)){
			create Dealer number: 1{
				location <- EntranceLocation;
				busy <- true;
				targetPoint <- EnormousLocation+{rnd(-20,20),rnd(10,-20)};
			}
			numberOfDealers <- numberOfDealers +1;
		}	
	}
	
	reflex globalPrint{
		//write "Step od simulation: " +time ;
		write "n dealers:"+numberOfDealers;
	}
}

species FestivalGuest skills:[moving]{
	rgb guestColor <- #red;
	bool informed <- false;
	
	int stepsWalked <- 0;
	int nDrink <- 0;
	int nFood <- 0;
	int nTobacco <- 0;
	int nBath <- 0;
	
	
	point targetPoint <- nil;
	bool busy <- false;
	
	float thirsty <- 0.0;
	float hungry <- 0.0;
	float pee <- 0.0;
	float smoke <- 0.0;
	float time <- 0.0;
	
	point WaterLocation <- nil;
	point FoodLocation <- nil;
	point BathLocation <- nil;
	point TobaccoLocation <- nil;
	
	Dealer dealer <- nil;
	
	//reflex logStatus {
	//	write "b:"+busy+" i:"+informed;
	//}
	
	reflex beIdle when: busy = false{
		do wander;
		
		if time>=1 {
			busy <- true;
			targetPoint <- ExitLocation;
		}
		
	}
	
	reflex countSteps when: busy =true {
		stepsWalked<-stepsWalked+1;
	}
	
	reflex report when: min ([nDrink, nFood, nTobacco, nBath]) = threshold {
		write "steps: "+stepsWalked;
		do die;
	}
	
	reflex incrementAttributes when: (max([thirsty, hungry, pee, smoke]) <1) and (busy = false) {
		int attribute <- rnd_choice([0.9, 0.04, 0.04, 0.01, 0.01, 0.01]);
		//int attribute <- rnd_choice([0.9, 0.5, 0.0, 0, 0.1]);
		if attribute = 1 {thirsty <- thirsty+0.1;}
		else if attribute = 2 {hungry <- hungry+0.1;}
		else if attribute = 3 {pee <- pee+0.1;}
		else if attribute = 4 {smoke <- smoke+0.1;}
		else if attribute = 5 {time <- time+0.1;}
		//write self.name + " thirsty: " + self.thirsty + " - hungry: " + self.hungry + " - pee: " + self.pee + " - smoke: " + self.smoke;
		
	}
	
	reflex moveToTarget when: targetPoint != nil {
		do goto target:targetPoint;
	}
	
	reflex moveToInformation when: ((max([thirsty, hungry, pee, smoke]) >= 1) or dealer!= nil) and (informed = false) {
		busy <- true;
//		write "dealer?"+dealer;
		if max([thirsty, hungry, pee, smoke]) >=1 {
			if thirsty >= 1 {
				self.guestColor <- #blue;
				targetPoint <- WaterLocation;
			}
			else if hungry >= 1 {
				self.guestColor <- #green;
				targetPoint <- FoodLocation;
			}
			else if pee >= 1 {
				self.guestColor <- #pink;
				targetPoint <- BathLocation;
			}
			else if smoke >= 1 {
				self.guestColor <- #black;
				targetPoint <- TobaccoLocation;
			}
			
			if (targetPoint = nil) {
				targetPoint <- InformationLocation;
			}
			
			
			if (location distance_to(InformationLocation) < 2) {
	
				ask InformationCentre { 
					if (myself.thirsty >= 1){
						myself.targetPoint<-WaterLocation;
						myself.WaterLocation<-WaterLocation;
					} else if (myself.hungry >= 1){
						myself.targetPoint<-FoodLocation;
						myself.FoodLocation<-FoodLocation;
					} else if (myself.pee >= 1){
						myself.targetPoint<-BathLocation;
						myself.BathLocation<-BathLocation;
					} else if (myself.smoke >= 1){
						myself.targetPoint<-TobaccoLocation;
						myself.TobaccoLocation<-TobaccoLocation;
					}
				}
				
				informed <- true;	
			}
		}else if dealer!= nil  and (location distance_to(InformationLocation) <= 2) {
				write "reported dealer";
				ask InformationCentre { 
					myself.targetPoint<-securityPosition;
					write " go to "+securityPosition;
				}
				informed <- true;	
				
				
		}
		
	}
	

	reflex enterStore when: targetPoint!=nil and dealer=nil and targetPoint!=InformationLocation and location distance_to(targetPoint) < 1{
		
		
		if (thirsty >= 1){
			thirsty<-0.0;
			nDrink <- nDrink +1;
		} else if (hungry >= 1){
			hungry<- 0.0;
			nFood <- nFood +1;
		} else if (pee >= 1){
			pee<- 0.0;
			nBath <- nBath+1;
		} else if (smoke >= 1){
			smoke<- 0.0;
			nTobacco <- nTobacco +1;
		}
		
		self.guestColor <- #red;
		targetPoint<-EnormousLocation+{rnd(-20,20),rnd(10,-20)};
		informed<-false;	
	}
	
	reflex arrivedToExit when:  location distance_to(ExitLocation) < 1 {
		busy<-true;
		numberOfPeople <- numberOfPeople-1;
		write numberOfPeople;
		do die;
	}
	
	reflex arrivedToStage when: busy=true and informed=false and location distance_to(targetPoint) < 2.5 {
		busy <- false;
		targetPoint <- nil;
	}
	
	reflex talkToNeighbour when: self.targetPoint = InformationLocation {
		list<FestivalGuest> others <- (FestivalGuest at_distance 5); // find all the neighboring animals in a radius of 5 meters 
		
	 	ask others {
//	 		write "I'm asking!";
	 		
	 		if(TobaccoLocation!= nil and myself.smoke >= 1 ){
	  			myself.TobaccoLocation<-TobaccoLocation;
	  		}
	 		
	 		if(BathLocation!= nil and myself.pee >= 1){
	  			myself.BathLocation<-BathLocation;
  			}
	 		
	 		if(WaterLocation!= nil and myself.thirsty >= 1){
	  			myself.WaterLocation<-WaterLocation;
	  		}
	  		
	 		if(FoodLocation!= nil and myself.hungry >= 1){
	  			myself.FoodLocation<-FoodLocation;
			}
		}
	 	
	}
	
	reflex findDealer when: busy=false{
		if length((Dealer at_distance 5)) > 0 {
			dealer <- (Dealer at_distance 5)[0];
			write "found dealer!!";
		}
	}
	
	reflex reportDealer when: dealer!= nil  and busy = false{
		busy <- true;
		informed <- false;
		targetPoint <- InformationLocation;
	}
	
	reflex askSecurity when: dealer!= nil  and busy = true and max([thirsty, hungry, pee, smoke]) <1 and location distance_to(targetPoint) < 1 {
		list<Security> guard <- (Security at_distance 1); // find all the neighboring Security in a radius of 1 meter
		
		write "talking to security";
		ask guard{
			target<-myself.dealer;
			//do goto target:point(target);
			myself.targetPoint <- point(myself.dealer);
			myself.dealer <- nil;	
		} 
		
		
	}
	
	aspect default{
		draw sphere(1) at: location color: guestColor;
	}
}

species Entrance{
	
	aspect default{
		draw square(5) at: location color: #green;
	}
}

species Exit{
	
	aspect default{
		draw square(5) at: location color: #red;
	}
}

species InformationCentre{
	
	point WaterLocation <- {90,50};
	point FoodLocation <- {80,10};
	point BathLocation <- {10,90};
	point TobaccoLocation <- {42,12};
	point securityPosition <- {3,50};
	
	aspect default{
		draw cube(5) at: location color: #yellow;
	}
}

species WaterFountain{
	
	aspect default{
		draw teapot(4) at: location color: #blue;
	}
}

species FoodStand{
	
	aspect default{
		draw cone3D(7,7) at: location color: #green;
	}
}

species Bathroom{
	
	aspect default{
		draw pyramid(5) at: location color: #pink;
	}
}

species TobaccoShop{
	
	aspect default{
		draw cylinder(3,9) at: location color: #brown;
	}
}

species EnormousStage{	
	rgb myColor <- #red;
	
	reflex changeColor {
		myColor <- flip(0.5) ? rnd_color(100, 200) : rnd_color(100, 200);
	}
	
	aspect default{
		draw square(40) at: location color: myColor;
	}
}

species Dealer skills:[moving]{
	rgb myColor <- #orange;
	point targetPoint <- nil;
	bool busy <- true;
	
	
	
	reflex moveToTarget when: targetPoint != nil {
		do goto target:targetPoint;
	}
	
	reflex beIdle when: busy = false{
		do wander;
	}
	
	reflex arriveToExit when: busy=true and location distance_to(ExitLocation) < 2 {
		numberOfDealers <- numberOfDealers-1;
		do die;
	}
	
	reflex arrivedToStage when: busy=true and location distance_to(targetPoint) < 1 {
		busy <- false;
		targetPoint <- nil;
	}
	aspect default{
		draw sphere(1) at: location color: myColor ;  
	}
}

species Security skills:[moving]{
	rgb myColor <- #red;
	Dealer target <- nil;
	
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

experiment Festival type: gui {
	/** Insert here the definition of the input and output of the model */
	output {
		display map type: opengl {
			species FestivalGuest;
			species Entrance;
			species Exit;
			species InformationCentre;
			species WaterFountain;
			species FoodStand;
			species Bathroom;
			species TobaccoShop;
			species EnormousStage;
			species Dealer;
			species Security;
		}
	}
}
