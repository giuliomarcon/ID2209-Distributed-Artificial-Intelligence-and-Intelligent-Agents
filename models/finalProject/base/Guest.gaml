/***
* Name: Guest
* Author: giuliomarcon
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model Guest
import "./../base/finalProject_0.gaml"


/* Insert your model definition here */

species Guest  skills:[moving,fipa]{
	rgb guestColor <- #red;	
	point targetPoint <- nil;
	
	int neighbouDistance <- 10;

	// Treats
	float drunkness <- 0.0;
	float talkative <- 0.0;
	float love <- 0.0;
	float thirsty <- 0.0;
	float chill2dance <- 0.0;
	string gender;
	
	
	
	float loveTrashold <- 1;
	float danceTrashold <- 0.5;
	float thirstyTrashold <- 1.0;

	int status<-3;
	
	int currentWaitingIteration <-0;
	
	int tableUsedIndex<- -1;
	message tableConversationMessage ;
	/*
	 * 0: want to drink
	 * 1: asked menu
	 * 2: received menu, ask for a drink
	 * 3: drinked, redy to go chill\dance;
	 * 4: wandering
	 * 5: approched guest reply
	 * 6: guests goes to the booked table
	 * 7: guest is at the table
	 * 8: guest going to tinderArea
	 * 9: guest reached tinderArea
	 * 10: guests matched at tinderArea, going to table
	 * 11: guests received approach in the tinderArea, evaluating partner
	 * 12: approcher (tinder) goinig to booked table
	 * 13: approcher (tinder) reached to booked table
	 * 
	 * 99: waiting ('talking') at the table, then go to tatus 3
	 */
	
	reflex moveToTarget when: targetPoint != nil {
		do goto target:targetPoint;
	}
	
	reflex updateThirsty when:thirsty<thirstyTrashold and status = 4 {
		if (flip (0.5) = true){
//		if(true){
			thirsty <- thirsty + rnd(0.0, 0.01);
			//thirsty <- thirsty + 0.3;
			//write name+ "thirsty:"+thirsty;
		}
	}
	
//	reflex introduceToBartender when:thirsty>=thirstyTrashold and location distance_to(BarLocation) < 0.5{
//		do start_conversation to: list(Bar) protocol: 'fipa-contract-net' performative: 'inform' contents: [drunkness] ;
//		thirsty<-0.0;
//		write name+ "ask the menu:"+thirsty color:#blue;
//	}

	reflex logTreats  when:false{
		write "drunkness:"+drunkness +" thirsty:"+thirsty+ " status:"+status +" love:"+love;
		write tableBookings;
	}
	
	reflex updateLove when:  status = 4{
		love<-love+rnd(0.0,0.008);
	}
	
	reflex askMenuBar when:status = 0 and thirsty>=thirstyTrashold and location distance_to(BarLocation) < 5{
		do start_conversation to: list(Bar) protocol: 'fipa-contract-net' performative: 'cfp' contents: [drunkness] ;
		
		thirsty<-0.0;
		status <- 1;
		//write name+ "ask the menu:"+thirsty color:#blue;
	}
	
	reflex receivedMenu when:status = 1 and !empty(proposes) {
		message m <- proposes[0];
		list<string> menu <- (m.contents);
		
		int numElem <- length(menu);
		int selectedItem <- rnd(0,numElem-1);
		
		
		//write name+"got menu:"+m.contents color:#purple;
		//write name+"Selected:"+selectedItem color:#purple;
		status <- 2;
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
	reflex selectBeverage when: status = 2 and !empty(informs){
		message m <- informs[0];
		float alchoolIncrement <- float(m.contents[0]);
		
		drunkness<- drunkness+alchoolIncrement;
		status <-3;
	}
	
	reflex imDrunk when:drunkness>=drunknesThreshold{
		//write name+"sono sbronzo!" color:#red;
	}
	
	reflex arrived2location when: targetPoint!= nil and location distance_to(targetPoint) < 1{
		targetPoint<-nil;
	}
	
	reflex dance when: status = 4{
		if (flip (chill2dance) = true){
			do wander;
		}
	}
	
    reflex goToStage when:status = 3 and chill2dance>= danceTrashold  and location distance_to(StageLocation) > 5 {
    	targetPoint<-StageLocation;
    	//write name + "belongs to party stage";
    }    
    
    reflex goToChill when:status = 3 and chill2dance< danceTrashold  and location distance_to(ChillLocation) > 5{
    	targetPoint<-ChillLocation;
    	//write name + "belongs to chill stage";
    }    
    
    reflex goToBar when:status  = 4 and thirsty>= thirstyTrashold {
    	targetPoint<-BarLocation;
    	status <-0;
    }
    reflex goToTinder when:status  = 3 and love >= loveTrashold {
    	//write name+"trashold reached";
    	love<-0.0;
    	targetPoint<-TinderLocation;
    	status <-8;
    }
    
    reflex arrivedAtdanceFloor when:status = 3 and (location distance_to(StageLocation)<5 or location distance_to(ChillLocation)<5) {
    	status <- 4;
    }
     
    reflex SecurityInteraction when:status =1 and !empty(informs) and informs[0].sender = list(Security)[0]{
		message m <- informs[0];
	
		targetPoint<-m.contents[0];
		
    }
    
    reflex checkCondition when:false  and status=4{
    	//write name+"status 4";
    }
    

    
    reflex mateReply when:status=5 and !empty(informs){
    	message m<-informs[0];
    	bool approchSuccess <- bool(m.contents[0]);
    
    	if(approchSuccess)	{
    		//going to the table
    		//write name + " approach suceed message";
    		point myPosition <- m.contents[1];
    		targetPoint<-myPosition;
    		status <- 6;
    		tableConversationMessage <- m;
    	}else{
    		//write name + " recived failed approach";
			do end_conversation message:m contents:[];
			
			//unbook table
			//write("mate reply unbook table");
    		int bookedTableNumber <- int(m.contents[1]);
    		tableBookings[bookedTableNumber]<-false;
    		
    		status <- 4;
    	}
    }
    
 
    
    reflex lookingForMate when:status=4 and location distance_to(ChillLocation)<5 and tableBookings contains(false){
    	//write name+" I'm lookig for a mate! " color:#darkgreen;
    	
    	list<Guest> neighbourGuests;
    	list<Guest> ChillneighbourGuests <- (ChillGuest at_distance neighbouDistance);
    	list<Guest> PartyneighbourGuests <- (PartyGuest at_distance neighbouDistance);
    	
    	
    	add PartyneighbourGuests all:true to: neighbourGuests;
    	add ChillneighbourGuests all:true to: neighbourGuests;
    	
    	    	
    	if(flip(talkative/50) and length(neighbourGuests)>0){
    		//write name+" there are:"+length(neighbourGuests)+" potential mates";
    		Guest potentialMate <- neighbourGuests[0];
	    	//write name+" found "+potentialMate color:#darkgreen;
	    	
    		bool tableStatus <- false;
    		
    		//booking table 
    		int tableIndex <-index_of(tableBookings,tableStatus);
    		tableBookings[tableIndex]<-true;
    		
    		
	    	//write name+" -> "+potentialMate +"lets go to table "+tableIndex color:#darkgreen;
    		
    		point myPosition <- tablePositions[tableIndex]-{tableRadius,0};//+{0,2*tableRadius};
    		point partnerPosition <- tablePositions[tableIndex]+{tableRadius,0};//+{0,2*tableRadius};
    		
    		//comunicating where to go
    		tableUsedIndex<-tableIndex;
    		
    		do start_conversation to: list(potentialMate) protocol: 'fipa-contract-net' performative: 'inform' contents: [partnerPosition,myPosition,tableIndex] ;
    		status <- 5;
    	}
    	
    }
    
    //receive inform message by other guest, but i'm already busy talking
    reflex receivedApproachFailed when:(status!=4 and status!=10 and status!=8 ) and !empty(informs) {//and list(Guest) contains informs[0].sender{
    	message m<- informs[0];
    	//TODO sistemare bug
    	if(length(m)<2){
    		// we should not get inside here!!
    		write "ocio:"+m ;
    	}else{
	    	tableUsedIndex <- int(m.contents[2]);
			//write name+" sorry "+m.sender+" i'm already busy (status:"+status+")";
			//write "proposed table:"+tableUsedIndex;
			do inform message:m contents:[false,tableUsedIndex];
			
		}
		
    }
    
    //receive inform message by other guest
    reflex receivedApproach when:status=4 and !empty(informs) {//and list(Guest) contains informs[0].sender{
    	message m<- informs[0];
		targetPoint<-m.contents[1];
		point matePoint<-m.contents[0];
		//write name+": "+m.sender+" approached me, going to point:"+targetPoint;
		do inform message:m contents:[true,matePoint];
		status <- 7;
    }
    
    //approching guest says its chill2dance vale
  	reflex rechedTable when: status=6 and location distance_to(targetPoint)<2 {
  		do cfp message:tableConversationMessage contents:[chill2dance];
  		status <-7;
  	}
  	
  	//approched guest receive chill2dance of approcher
  	reflex getC2D when: status = 7 and !empty(cfps){
		message m <- cfps[0];
		float c2dApprocher <- float(m.contents[0]); 
		float c2dApprocherExtreme <- float(m.contents[0]); 
		float c2dExtreme <- chill2dance;
		
		if(c2dApprocherExtreme > 0.5){
			c2dApprocherExtreme <- 1 - c2dApprocherExtreme;	
		}
		
		if(c2dExtreme > 0.5){
			c2dExtreme <- 1 - c2dExtreme;	
		}
		
		//approcher  chilldance is  closer to the relative extreme than mine
		if(c2dApprocherExtreme < c2dExtreme){
			if( c2dApprocher>0.5){
				chill2dance <- chill2dance + communicationIncreasigFactor;
			}else{
				chill2dance <- chill2dance - communicationIncreasigFactor;
			}
			do propose  message:m contents:[0];
			
			
		}else{
			//mine chill2dance is closer to the relative extreme
			if(chill2dance > 0.5){
				do propose  message:m contents:[communicationIncreasigFactor];
			}else{
				do propose  message:m contents:[0-communicationIncreasigFactor];
			}
		}
		
		
    	//write name+"sent info about the outcome of the conversation " + m.contents[0] + "go back to previous activity";
    	//waiting for a wgile at the table before go back to previous activity
    	status <-99;
    	
  	}
    
    //received info about the outcome of the conversation
    reflex gotProposal when: !empty(proposes) and status = 7 {
    	message m <- proposes[0];
    	chill2dance <- chill2dance + float(m.contents[0]);
    	// TODO end_conversation
    	
    	//write name+"received info about the outcome of the conversation " + m.contents[0] + "go back to previous activity";
    	
    	//waiting for a wgile at the table before go back to previous activity
    	status <-99;
    }
    
    // REached TinderArea, looking for a soul mate
    reflex lookingForSoulMate when:status=8 and location distance_to(TinderLocation)<5 and tableBookings contains(false){
    	//status<-9;
    	//write name+" reached tinderArea";
    	list<Guest> neighbourGuests;
    	list<Guest> ChillneighbourGuests <- (ChillGuest at_distance neighbouDistance);
    	list<Guest> PartyneighbourGuests <- (PartyGuest at_distance neighbouDistance);
    	
    	
    	add PartyneighbourGuests all:true to: neighbourGuests;
    	add ChillneighbourGuests all:true to: neighbourGuests;
    	
    	neighbourGuests<-shuffle(neighbourGuests);
    	if(flip(talkative/30) and length(neighbourGuests)>0){
    		//write name+" in  tinderArea there are:"+length(neighbourGuests)+" potential mates" color:#red;
    		Guest potentialMate <- neighbourGuests[0];
	    	//write name+" in  tinderArea  found "+potentialMate color:#darkgreen;
	    	
    		bool tableStatus <- false;
    		
    		//booking table 
    		int tableIndex <-index_of(tableBookings,tableStatus);
    		tableBookings[tableIndex]<-true;
    		
    		
	    	//write name+"[in  tinderArea ]-> "+potentialMate +"lets go to table "+tableIndex color:#darkgreen;
    		
    		point myPosition <- tablePositions[tableIndex]-{tableRadius,0};
    		point partnerPosition <- tablePositions[tableIndex]+{tableRadius,0};
    		
    		//comunicating where to go
    		tableUsedIndex<-tableIndex;
    		
    		do start_conversation to: list(potentialMate) protocol: 'fipa-contract-net' performative: 'inform' contents: [partnerPosition,myPosition,tableIndex] ;
    		status <- 10;
    	}else{
    		//write name+" waiting inthe tinderArea status:"+status color:#lightblue;
    	}
    	
    }
    

    //receive approach message by other guest
    reflex receivedTinderApproach when:status=8 and !empty(informs) {//and list(Guest) contains informs[0].sender{
    	message m<- informs[0];
		targetPoint<-m.contents[1];
		point matePoint<-m.contents[0];
		//write name+": "+m.sender+" approached me in  tinderArea , going to point:"+targetPoint color:#blue;
		do inform message:m contents:[true,matePoint];
		status <- 11;
    }
    
    //the approched guest replied to table message
    reflex tinderMateReply when:status=10 and !empty(informs){
    	message m<-informs[0];
    	bool approchSuccess <- bool(m.contents[0]);
    
    	if(approchSuccess)	{
    		//going to the table
    		//write name + " approach suceed message";
    		point myPosition <- m.contents[1];
    		targetPoint<-myPosition;
    		status <- 12;
    		tableConversationMessage <- m;
    	}else{
    		//write name + " recived failed approach";
			do end_conversation message:m contents:[];
			
			//unbook table
    		int bookedTableNumber <- int(m.contents[1]);
    		tableBookings[bookedTableNumber]<-false;
    		
    		status <- 8;
    	}
    }
    
    //approching tinder guest says its chill2dance vale
  	reflex rechedTinderTable when: status=12 and location distance_to(targetPoint)<2 {
  		do cfp message:tableConversationMessage contents:[chill2dance];
  		status <-13;
  	}
  	
    //approched guest receive chill2dance of approcher
  	reflex getTinderC2D when: status = 11 and !empty(cfps){
		message m <- cfps[0];
		float c2dApprocher <- float(m.contents[0]); 
		float c2dApprocherExtreme <- float(m.contents[0]); 
		float c2dExtreme <- chill2dance;
		
		//write name+ " evauleting tinder mate C2D of"+m.sender;
		if(c2dApprocherExtreme > 0.5){
			c2dApprocherExtreme <- 1 - c2dApprocherExtreme;	
		}
		
		if(c2dExtreme > 0.5){
			c2dExtreme <- 1 - c2dExtreme;	
		}
		
		//approcher  chilldance is  closer to the relative extreme than mine
		if(c2dApprocherExtreme < c2dExtreme){
			if( c2dApprocher>0.5){
				chill2dance <- chill2dance + communicationIncreasigFactor;
			}else{
				chill2dance <- chill2dance - communicationIncreasigFactor;
			}
			do propose  message:m contents:[0];
			
			
		}else{
			//mine chill2dance is closer to the relative extreme
			if(chill2dance > 0.5){
				do propose  message:m contents:[communicationIncreasigFactor];
			}else{
				do propose  message:m contents:[0-communicationIncreasigFactor];
			}
		}
		
		
    	//write name+"sent info about TINDER the outcome of the conversation " + m.contents[0] + "go back to previous activity" color:#purple;
    	//waiting for a wgile at the table before go back to previous activity
    	status <-99;
    	//unbook tabels
    	//tableBookings[tableUsedIndex]<- false;
  	}
        
    //received info about the outcome of the Tinder conversation
    reflex gotTinderDateOutcome when: !empty(proposes) and status =13 {
    	message m <- proposes[0];
    	chill2dance <- chill2dance + float(m.contents[0]);
    	// TODO end_conversation
    	
    	//write name+"received info about the TINDER outcome of the conversation " + m.contents[0] + "go back to previous activity" color:#violet;
    	
    //waiting for a wgile at the table before go back to previous activity
    	status <-99;
    }
        //received info about the outcome of the conversation

	reflex waitBeforeGoingToPreviousActivity when: status = 99 and currentWaitingIteration <= WAITING_ITERATIONS{
		if(currentWaitingIteration >= WAITING_ITERATIONS){
		//go back to previous activit
    		status <-3;
    		currentWaitingIteration <- 0;		
    		//unbook tabels
			write("leaving the table, unbooking");
			
			if(tableUsedIndex!=-1){
	    		tableBookings[tableUsedIndex]<- false;
	    		tableUsedIndex <- -1;
    		}
    		
    	}else{
    		currentWaitingIteration <-	currentWaitingIteration + 1;
    		
    	}
    	
	}
    
 
    reflex logStatus when:false {
    	write name + "status:"+status;
    }

    //on the exit square
    reflex exitFestival when: location distance_to(ExitLocation)<1{
    	do die;
    }
    
    
    aspect default{
       	draw cone3D(1.3,2.3) at: location color: #slategray ;
    	draw sphere(0.7) at: location + {0, 0, 2} color: #salmon ;
    }
    
    	
} 

species ChillGuest parent: Guest{
	
	bool increasingC2D;
	
	init{
		talkative <- rnd(0.0,1.0);
		chill2dance <- rnd(0.0,0.3);
		increasingC2D<-flip(0.3);
	}
	
	reflex updateC2D when: status=4{
		if(increasingC2D ){
			float incresingStep <- rnd(0.0,0.0002);
			
			if ((incresingStep + chill2dance)<= 1){
				chill2dance <- chill2dance + incresingStep;
			}else{
				increasingC2D <-false;
				status<-3;
			}
		}else{
			float decresingStep <- rnd(0.0,0.002);
			
			if ((chill2dance-decresingStep)>= 0){
				chill2dance <- chill2dance - decresingStep;
			}else{
				increasingC2D <-true;
				status<-3;
			}
		}
		
	}
		
		
		
   	aspect default{
       	draw cone3D(1.3,2.3) at: location color: #slategray ;
    	draw sphere(0.7) at: location + {0, 0, 2} color: #blue ;
    }
}

species PartyGuest parent: Guest{
	bool increasingC2D;
	init{
		talkative <- rnd(0.0,1.0);
		chill2dance <- rnd(0.4,1.0);
		increasingC2D<-flip(0.8);
	}
	
	
	reflex updateC2D when: status=4{
		if(increasingC2D ){
			float incresingStep <- rnd(0.0,0.002);
			
			if ((incresingStep + chill2dance)<= 1){
				chill2dance <- chill2dance + incresingStep;
			}else{
				increasingC2D <-false;
				status<-3;
			}
		}else{
			float decresingStep <- rnd(0.0,0.0002);
			
			if ((chill2dance-decresingStep)>= 0){
				chill2dance <- chill2dance - decresingStep;
			}else{
				increasingC2D <-true;
				status<-3;
			}
		}
		
		
		
	}
	
	reflex logdrunkness when:false{
		write "drunkness:"+drunkness;
	}
	
	
   aspect default{
       	draw cone3D(1.3,2.3) at: location color: #slategray ;
    	draw sphere(0.7) at: location + {0, 0, 2} color: #red ;
    }
}

