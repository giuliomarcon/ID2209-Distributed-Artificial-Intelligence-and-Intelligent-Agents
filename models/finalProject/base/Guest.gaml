/***
* Name: Guest
* Author: giuliomarcon
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model Guest
import "finalProject_0.gaml"


/* Insert your model definition here */

species Guest  skills:[moving,fipa]{
	rgb guestColor <- #red;	
	point targetPoint <- nil;
	point myTablePosition <- nil;
	int tableIndexUsed <- -1;
	
	agent communicationPartener <- nil;
	int neighbouDistance <- 10;
	
	//message descriptor where to store the ack before leaving the area, and to be used to send a messaged when reached the table
	message mTemp;

	// Treats
	float drunkness <- 0.0;
	//float talkative <- 0.0;
	float talkative <- 1.0;
	float love <- 0.0;
	float thirsty <- 0.0;
	float chill2dance <- 0.0;
	string gender;
	string desiredLoveMateGender;
	
	
	
	float loveTrashold <- 1.0;
	float danceTrashold <- 0.5;
	float thirstyTrashold <- 0.8;

	int watchdogCounter;
	int status<-0;
	
	int currentWaitingIteration <-0;
	string partnerName <- nil;
 	  


	init {
		if(flip(0.5)){
			gender<-'M';
		}else{
			gender<-'F';
		}
		
		if(flip(0.5)){
			desiredLoveMateGender<-'M';
		}else{
			desiredLoveMateGender<-'F';
		}
	}
	
	reflex moveToTarget when: targetPoint != nil {
		do goto target:targetPoint;
	}
	
	//update needs
	reflex updateThirsty when:thirsty<=thirstyTrashold {
		thirsty <- thirsty + rnd(0.0, 0.01);
		
	}
		
	reflex updateLove when:  love<loveTrashold{
		love<-love+rnd(0.0,0.008);
	}	
	
	reflex updateChill2Dance when:  chill2dance<1{
		chill2dance<-chill2dance+rnd(0.0,0.0008);
	}
	
	



    reflex goToChillArea when: status = 0 and chill2dance < danceTrashold{
    	targetPoint<-ChillLocation;
    	status <- 2;
    }
    
    
	reflex goToTinderArea when: status = 0 and love>= loveTrashold{
		
		write "["+name+"]("+status+") need to fine love" ;
	  	targetPoint <- TinderLocation;
    	status <- 20;
	}
        
    reflex goToBarLocation when:status  = 0 and thirsty>= thirstyTrashold {
    	targetPoint<-BarLocation;
    	status <-30;
    }
    
     reflex goToDanceArea when:status = 0 and chill2dance>= danceTrashold{
    	targetPoint<-StageLocation;
    	status <- 40;
    }   
      
     /****************** DANCE INTERACTIONS ***************************************/	    
   
    reflex reachedDanceArena when: status = 40 and location distance_to(StageLocation) < 1 {
		status <- 41;
		do wander;
    }
    
    reflex doDance when: status = 41 {
		if (chill2dance > 0 and location distance_to(StageLocation) <= 15){
			do wander ;	
			status <- 41;	
			chill2dance <- chill2dance - rnd(0.0, 0.01);
		}else{
			status <- 100;
		}
    }
    

    //*************************** CHILL INTERACTIONS ****************************************
    reflex arrivedAtChillArea when: location distance_to(ChillLocation) < 1 and status = 2{
    	targetPoint <- nil;
    	status <-3;
    }
    
    reflex randomWaitChillArea when: status = 3 and empty(informs){
		float length<-10.0;
		targetPoint <- nil;
		communicationPartener<-nil;
		

		if(flip(talkative/50) and empty(informs) ){
			status<-4;
		}else{
    			do wander bounds: square(length);	
 
		}
    	
    }
    
    //initiator start conversation
    reflex startConverationChill when: status = 4{
    	//in the mean time somebody contacted me, go to reply
    	if (!empty(informs)){
	    	write "["+name+"]("+status+") While I was going to approch somebody i recevide an approcha, ,go back to status 3 sender:"+informs[0].sender color:#blue;
    		status <- 3;
    	}else{   	
	    	list<Guest> neighbourGuests;
	    	list<Guest> ChillneighbourGuests <- (ChillGuest at_distance neighbouDistance);
	    	list<Guest> PartyneighbourGuests <- (PartyGuest at_distance neighbouDistance);
	    	    	    	
	    	add PartyneighbourGuests all:true to: neighbourGuests;
	    	add ChillneighbourGuests all:true to: neighbourGuests;
	    	
	    	if(length(neighbourGuests)>0){
	    		Guest potentialMate <- neighbourGuests[0];
		    	    		
	    		//booking table 
	    		tableIndexUsed <- rnd (0,tableNumber-1);
		    
		    	if(first(tableIndexUsed,false)= nil){
		    		write "["+name+"]("+status+") no free table found";
		    	}
		    	
			    loop while: tableBookings[tableIndexUsed] { 
		    		tableIndexUsed <- rnd (0,tableNumber-1);
				}
		    	
		    	
		    	
	    		tableBookings[tableIndexUsed]<-true;
	    		    		
	    		communicationPartener<-potentialMate;
	    		
	    		write "["+name+"]("+status+") Starting conversation with "+potentialMate color:#blue;
	    		ask potentialMate{
	    			write " his status is "+status color:#blue;
	    			write " #######################################" color:#blue;
	    		}
	    		do start_conversation to: list(potentialMate) protocol: 'fipa-contract-net' performative: 'inform' contents: [tableIndexUsed] ;
	    		status <- 6;
	    		
	    		write "["+name+"]("+status+") Start conversation with "+potentialMate color:#blue;
	    	}else{
	    		status <-100;
	    		write "["+name+"]("+status+") failed start conversation, go back to status 100" color:#blue;
	    	}
    	
    	}
    }
    
    //target catch starting conversation and reply with ACK
    reflex catchConversationStart when:status=3 and !empty(informs){

    	message m<-informs[0];
    	tableIndexUsed <- int(m.contents[0]);
    	communicationPartener <- Guest(m.sender);
    	write "["+name+"]("+status+") reply ACK to "+m.sender color:#red;
    	do reply performative:"inform" message:m  contents:[true];
    	
    	status <- 5;
    	write "["+name+"]("+status+")" color:#red;
    	
    	
    }

    

    
    
    reflex gotACKfromChillGues when: status = 6 and !empty(informs) and (informs[0].sender = communicationPartener) {
    	mTemp<-informs[0];
    	write "["+name+"] got inform meesage:"+mTemp color:#blue;
    	bool  approachStatus <- bool(mTemp.contents[0]);
    	
    	write "["+name+"]("+status+") message: "+mTemp color:#blue;
    	
    	if(approachStatus){
	    	targetPoint <-  tablePositions[tableIndexUsed]-{tableRadius,0};
	    	write "["+name+"]("+status+") going to table: "+tableIndexUsed+" position:"+targetPoint color:#blue;
    	}else{
    		do end_conversation message: mTemp contents:[];
    		tableBookings[tableIndexUsed]<-false;
	    	write "["+name+"]("+status+") ABORT GOING TO TABLE" color:#purple;
    		
    		status <-100;
    	}
    }
    
    //initiator reached table
    reflex initiatoreReachedTableChill when:status  = 6 and targetPoint!=nil and location distance_to(targetPoint)<= 2{
    	write "["+name+"]("+status+")Reached table" color:#blue;
		status <- 8;
    }
    
    //target goes to table
    reflex targetGoesToTableChill when:status = 5 {
    	targetPoint <- tablePositions[tableIndexUsed]+{tableRadius,0};
    	write "["+name+"]("+status+")I'm going to table:" + tableIndexUsed + " position:"+targetPoint color:#red;
    	status <- 7;
    }
    
    // target agent is at table
    reflex targetAtTable when: status=7 and location distance_to(targetPoint)<= 2{
		status <- 9;
    	write "["+name+"] reached table" color:#red;
	}

	//initiator communicate its Chill2Dance to target
	reflex sendC2dToTarget when: status  = 8 {
		do cfp message:mTemp contents:[chill2dance];
    	write "["+name+"] at the table sending chill2dance:"+chill2dance+ "to:"+mTemp.sender color:#blue;
  
		status <- 10;
	}

	//target recevide initator C2D
	//update its own chill 2 dance
	reflex gotC2D when:status = 9 and !empty(cfps) and (cfps[0].sender = communicationPartener){
		
    	write "["+name+"] got C2D" color:#red;
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
			if( c2dApprocher>0.3){
				if(chill2dance + communicationIncreasigFactor <= 1){
					chill2dance <- chill2dance + communicationIncreasigFactor;
				}
			}else{
				if( chill2dance - communicationIncreasigFactor*0.1>= 0){
					//chill2dance <- chill2dance - communicationIncreasigFactor*0.1;
				}
			}
			
			do propose  message:m contents:[0];
			
			
		}else{
			//mine chill2dance is closer to the relative extreme
			if(chill2dance > 0.3){
				do propose  message:m contents:[communicationIncreasigFactor];
			}else{
				do propose  message:m contents:[0-communicationIncreasigFactor*0.1];
			}
		}
		

    	status <-99; 	
		
	}
	
	//received info about the outcome of the conversation
    reflex gotProposal when: status = 10 and !empty(proposes)  and (proposes[0].sender = communicationPartener) {
    	message m <- proposes[0];
    	chill2dance <- chill2dance + float(m.contents[0]);
    	do end_conversation message:m contents:[];
    	
    	status <-99;
    }
	// ****************************** TINDER INTERACTIONS ******************************//
    
    reflex atTinderArea when:status = 20 and  location distance_to(TinderLocation)<5{
    	
    	status <- 21;
    }
    
    reflex lookAround when: status = 21 and empty(informs){
    	do wander;
    	
		
    	if (flip(talkative/30) ){
    		status <- 22;
    	}else if(location distance_to(TinderLocation) > 10){
    		//status <- 100;
    		status <- 21;
    	}
    }
    
	// catched starting conversation
    reflex receivedApproach when:status=21 and !empty(informs) {//and list(Guest) contains informs[0].sender{
    	message m<- informs[0];
    	communicationPartener <- m.sender;
	    	
		tableIndexUsed<-int(m.contents[0]);
		
		write "["+name+"]("+status+") catched tinder conversation starting from:"+m.sender + "giving ACK" color:#blue;
		do inform message:m contents:[true];
		
		targetPoint  <- tablePositions[tableIndexUsed]+{tableRadius,0};
		status <- 23;
		
		write "["+name+"]("+status+") status updated" color:#blue;
    }
    
    // Reached TinderArea, starting conversation to agent   
    reflex lookingForSoulMate when:status=22 and tableBookings contains(false){
    	list<Guest> neighbourGuests;
    	list<Guest> ChillneighbourGuests <- (ChillGuest at_distance neighbouDistance);
    	list<Guest> PartyneighbourGuests <- (PartyGuest at_distance neighbouDistance);
    	
    	
    	add PartyneighbourGuests all:true to: neighbourGuests;
    	add ChillneighbourGuests all:true to: neighbourGuests;
    	
    	
    	neighbourGuests<-shuffle(neighbourGuests);
    	if(length(neighbourGuests)>0){
    		Guest potentialMate <- neighbourGuests[0];
	    	
			write "["+name+"]("+status+") approching:"+potentialMate color:#red;
	    	
	    	tableIndexUsed <- rnd (0,tableNumber-1);
		    
	    	if(first(tableIndexUsed,false)= nil){
	    		write "["+name+"]("+status+") no free table found";
	    	}
		    	
		    loop while: tableBookings[tableIndexUsed] { 
	    		tableIndexUsed <- rnd (0,tableNumber-1);
			}
	    	
    		tableBookings[tableIndexUsed]<-true;
    		
    		
    		//comunicating where to go
    		tableIndexUsed<-tableIndexUsed;
    		
    		communicationPartener <- potentialMate;
    		do start_conversation to: list(potentialMate) protocol: 'fipa-contract-net' performative: 'inform' contents: [tableIndexUsed] ;
    		status <- 24;
    	}else{
			write "["+name+"]("+status+") no neighbourGuests, falling back to 100" color:#red;
    		status <- 100;
    	}
    	
    }
	

    
    //initator get ACK from target
    //Go to table
    reflex gotTinderACK when:status = 24 and !empty(informs) and (informs[0].sender = communicationPartener){
    	mTemp <- informs[0];
    	bool response <- bool(mTemp.contents[0]);
    	
		write "["+name+"]("+status+") got ACK (or NACK) from:"+mTemp.sender+" value:"+response color:#red;
		
    	if (response){
	    	targetPoint <- tablePositions[tableIndexUsed]-{tableRadius,0};
	    	
	    	status <- 26;
    	}else{
    		
    		do end_conversation message: mTemp contents:[];
    		tableBookings[tableIndexUsed]<-false;
    		
			write "["+name+"]("+status+") ending conversation with:"+mTemp.sender color:#purple;
    		status <- 100;
    	}
		write "["+name+"]("+status+") moved to next stage after reading response" color:#red;
    } 
    
   
    
    //initiator arrived at table, send its gender
    reflex initiatorAtTinderTable when:status = 26 and targetPoint!=nil and location distance_to(targetPoint) <= 2 {
		write "["+name+"]("+status+") Informing "+mTemp.sender+" my gender:"+gender color:#red;
    	do inform message: mTemp contents:[gender];
    	status <-28;
    }
    
    
    //target agent arrived at table and got gender from initiator
    reflex targetAtTinderTable when:status = 23 and location distance_to(tablePositions[tableIndexUsed]+{tableRadius,0}) <= 2  and !empty(informs)  and (informs[0].sender = communicationPartener){
		message m <- informs[0];
		string partnerGender <- string(m.contents[0]);
		
		write "["+name+"]("+status+") I have reached the tabele and received gender infos from approcher " color:#gold;
		write "["+name+"]("+status+") message:"+m color:#gold;
		
		if (partnerGender = desiredLoveMateGender){
			write "["+name+"]("+status+") informing "+m.sender + " with ACK and my gender:"+gender color:#gold;
			do inform message:m contents:[true,gender];
    		status <- 25;
		}else{
			write "["+name+"]("+status+") informing "+m.sender + " with NACK and resetting to 21" color:#blue;
			do inform message:m contents:[false];
			status <- 100;	
		}
    }
    
	reflex initiatorGotRensponseTinder when: status = 28 and !empty(informs)  and (informs[0].sender = communicationPartener){
		message m <- informs[0];
		bool chatResponse <- bool(m.contents[0]);
		write "["+name+"]("+status+") Got chat response : "+chatResponse+" from:"+m.sender color:#red;
		if(chatResponse){
			string targetGender <- string(m.contents[1]);
			if(targetGender = desiredLoveMateGender){
				do inform message:m contents:[true];
				love <-0.0;
				status <- 99;
			}else{
				
				write "["+name+"]("+status+") should reply fals e to:"+m.sender color:#red;
				do inform message:m contents:[false];
				status <- 100;
			}
			
		}else{
			do end_conversation message:m contents:[];
			//do inform message:m contents:[false];
			status <- 100;
		}
		write "["+name+"]("+status+") updated status accordingly"  color:#red;
	}

	
	reflex targetReceivedOutcomeTinder when:status = 25 and !empty(informs)  and (informs[0].sender = communicationPartener){
		message m <- informs[0];
		bool chatResponse <- bool(m.contents[0]);
		
		write "["+name+"]("+status+") ++++++++++++++ IN THE FUKING STATE 25"+mTemp.sender color:#purple;
		
		if(chatResponse){
			love<-0.0;
			status <- 99;
		}else{	
			status <- 100;
		}
		do end_conversation message:m contents:[];
			
		write "["+name+"]("+status+") ending conversation with:"+mTemp.sender color:#purple;
		
	}
	
	
	// ****************************** BAR INTERACTIONS ******************************//
	reflex goToBar when: status= 0 and thirsty>=thirstyTrashold {
		status <- 30;
		targetPoint <-BarLocation;
		write "["+name+"]("+status+") need to drink" color:#brown;
	}
	
	
	reflex askMenuBar when:status = 30 and location distance_to(BarLocation) < 5{
		communicationPartener <- list(Bar)[0];
		do start_conversation to: list(Bar) protocol: 'fipa-contract-net' performative: 'cfp' contents: [drunkness] ;
		
		write "["+name+"]("+status+") communicationPartener:"+communicationPartener color:#brown;
		status <- 31;
		//write name+ "ask the menu:"+thirsty color:#blue;
	}
	
	reflex receivedMenu when:status = 31 and !empty(proposes) {
		message m <- proposes[0];
		list<string> menu <- (m.contents);
		
		int numElem <- length(menu);
		int selectedItem <- rnd(0,numElem-1);
		
		write "["+name+"]("+status+") communicationPartener:"+communicationPartener color:#brown;
		status <- 32;
		do accept_proposal message:m contents: [selectedItem];
	}	
	
	reflex selectBeverage when: status = 32 and !empty(informs){
		write "["+name+"]("+status+") communicationPartener:"+communicationPartener color:#brown;
		message m <- informs[0];
		float alchoolIncrement <- float(m.contents[0]);
		
		drunkness<- drunkness+alchoolIncrement;
		
		thirsty <- 0.0;
		status <-100;
	}
	
	// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++//
	


   

    
	// +++++++++++++++++++++++++++  Security interactions ++++++++++++++++++++++++++++++++++++++++++++++++
	reflex SecurityInteraction when:status =31 and !empty(informs) and informs[0].sender = list(Security)[0]{
		message m <- informs[0];
		targetPoint<-m.contents[0];	
		write "["+name+"]("+status+") I was caugth by the police! " color:#salmon;
    }
    
  	
	// +++++++++++++++++++++++++ fsm functioning ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    reflex closePendingApproces when: !empty(informs) and (informs[0].sender != communicationPartener) {
	   
    	loop m over: informs{ 
    		if(m.sender != communicationPartener){
		    	write "["+name+"]("+status+") dropping pending approches" color:#purple;
		    	write "["+name+"]("+status+") m.sender:"+m.sender+" communicationPartener:"+communicationPartener color:#purple;
		    	write "message:"+informs[0] color:#purple;
		    	do reply message:m performative:"inform" contents:[false];
	    	}
		}
	}
	
	// catching start of conversation while already busy
   reflex catchWrongConversationStart when: !empty(informs) and (communicationPartener = nil or informs[0].sender!=communicationPartener){
   		message m <-informs[0];
   		write "["+name+"]("+status+") cathcehd wrong conversation by ("+m.sender+", replying false" color:#orange;
   		if (m.sender != communicationPartener){
   			do reply message:m performative:"inform" contents:[false];
   		}
 
    	
   }

	reflex waitBeforeGoingToPreviousActivity when: status = 99 and currentWaitingIteration <= WAITING_ITERATIONS{
		if(currentWaitingIteration >= WAITING_ITERATIONS){
		//go back to previous activit
    		
    		currentWaitingIteration <- 0;		
    		//unbook tabels
			if(tableIndexUsed!=-1){
	    		tableBookings[tableIndexUsed]<- false;
	    		tableIndexUsed <- -1;
    		}
    		status <- 100;
    	}else{
    		currentWaitingIteration <-	currentWaitingIteration + 1;
    		
    	}
	}
	
	reflex goBackToActivities when: status = 100{
    		communicationPartener<- nil;
    		loop m over: informs{
    			do end_conversation message:m contents:[];
    		}
    		loop m over: cfps{
    			do end_conversation message:m contents:[];
    		}
    		loop m over: proposes{
    			do end_conversation message:m contents:[];
    		}
    		
    		//unbook talbe
    		if(tableIndexUsed!= -1){
    			tableBookings[tableIndexUsed] <- false;
    			tableIndexUsed <- 1;
			}
    		write "["+name+"]("+status+") length of informs"+length(informs);
    		status <- 0;
	}
	
    
	reflex arrived2location when: targetPoint!= nil and location distance_to(targetPoint) < 1{
		targetPoint<-nil;
	}
	

    //logging
 
    reflex logStatus when:false {
    	write name + "status:"+status;
    } 
    reflex logTables when:false {
    	write tableBookings;
    }
    
	reflex logTreats  when:false{
		write "drunkness:"+drunkness +" thirsty:"+thirsty+ " status:"+status +" love:"+love;
	
	}

    
    aspect default{
       	draw cone3D(1.3,2.3) at: location color: #slategray ;
    	draw sphere(0.7) at: location + {0, 0, 2} color: #salmon ;
    }
    
    	
} 

species ChillGuest parent: Guest{
	
	bool increasingC2D;
	
	init{
		//talkative <- rnd(0.0,1.0);
		talkative <- 1.0;
		chill2dance <- rnd(0.0,0.3);
		increasingC2D<-flip(0.3);
	}
	/*
	
	reflex updateC2D when: status=4{
		
		 // we use increasing beacuse in this way c2d will monotonically increase until 1, then it will monotonically decrese until 0.01,
		 // This is done to avoid rapid changeing behaviour
		 
		if(increasingC2D ){
			float incresingStep <- rnd(0.02,0.04);
			
			if ((incresingStep + chill2dance)<= 1){
				chill2dance <- chill2dance + incresingStep;
			}else{
				increasingC2D <-false;
				status<-3;
			}
		}else{
			float decresingStep <- rnd(0.0,0.002);
			
			if ((chill2dance-decresingStep)>= 0.01){
				chill2dance <- chill2dance - decresingStep;
			}else{
				increasingC2D <-true;
				
				status<-3;
			}
		}
		
	}
		
*/
    //on the exit square
    reflex exitFestival when: location distance_to(ExitLocation)<1{
    	numberOfChill <-numberOfChill-1;
    	
    	do die;
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

	reflex updateChill2Dance when:  chill2dance<1{
		chill2dance<-chill2dance+rnd(0.0,0.005);
	}
/*	
	
	reflex updateC2D when: status=4{
		if(increasingC2D ){
			float incresingStep <- rnd(0.001,0.005);
			
			if ((incresingStep + chill2dance)<= 1){
				chill2dance <- chill2dance + incresingStep;
			}else{
				increasingC2D <-false;
				status<-3;
			}
		}else{
			float decresingStep <- rnd(0.0,0.0002);
			
			if ((chill2dance-decresingStep)>= 0.01){
				chill2dance <- chill2dance - decresingStep;
			}else{
				increasingC2D <-true;
				status<-3;
			}
		}
		
		
		
	}
	
*/
			
    //on the exit square
    reflex exitFestival when: location distance_to(ExitLocation)<1{
    	numberOfParty <-numberOfParty-1;
    	
    	do die;
    }
    
	
   aspect default{
       	draw cone3D(1.3,2.3) at: location color: #slategray ;
    	draw sphere(0.7) at: location + {0, 0, 2} color: #red ;
    	

   
    }
    


}

