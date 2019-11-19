/***
* Name: Festival
* Author: giuliomarcon
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model Festival

global {
	/** Insert the global definitions, variables and actions here */
	point EnormousLocation <- {50,80};
	point EntranceLocation <-{0,0};
	point ExitLocation <-{100,100};
	point Shop1 <- {20, 10};

	
	string informStartAcutionMSG <- 'inform-start-of-auction';
	string informEndAcutionFailedMSG <- 'auction-failed';
	string wonActionMSG <- 'won-auction';
	string lostActionMSG <- 'lost-auction';
	string acceptProposal <-'accepted-proposal';
	string refusedProposal <-'rejected-proposal';
	int nbOfParticipants <- 0;
	
	
	// number of vist at each shop before quitting
	int threshold <- 100;
	
	init{
		
		create Initiator number: 1{
			location <- Shop1;
		}
		
		create Entrance number: 1{
			location <-EntranceLocation;
		}
		
		create Exit number: 1{
			location <- ExitLocation;
		}
		
		create EnormousStage number: 1 {
			location <- EnormousLocation;
		}

	}
	reflex spawnPartecipant when: nbOfParticipants<5{
		create Participant number: 1{
			location <- EntranceLocation;
//			busy <- true;
//			targetPoint <- {4,30};
			targetPoint<-EnormousLocation+{rnd(-5,5),rnd(5,-5)};
		}
		nbOfParticipants <- nbOfParticipants +1;
	}
	
	reflex globalPrint{
		//write "Step od simulation: " +time ;
	}
}

species Participant skills:[moving,fipa]{
	rgb guestColor <- #red;
		
	point targetPoint <- nil;
	bool busy <- false;
			
	reflex beIdle when: targetPoint = nil{
		do wander;
		
//		if time>=1 {
//			busy <- true;
//			targetPoint <- ExitLocation;
//		}
		
	}

	
	reflex moveToTarget when: targetPoint != nil {
		do goto target:targetPoint;
	}	
	
//	reflex arrivedToExit when:  location distance_to(ExitLocation) < 1 {
//		busy<-true;
//		nbOfParticipants <- nbOfParticipants-1;
//		write 'arrived exit'+nbOfParticipants;
//		do die;
//	}
//	
	reflex arrivedToStage when: location distance_to(EnormousLocation) < 5.5 and busy = false {
//		busy <- false;
		targetPoint <- nil;
	}
	
	int step<-0;
	int maxPrice <-rnd(750,950);
	
	// TODO fix
	reflex auctionStarted when: !empty(informs) and step = 0{
		busy <- true;
		targetPoint <- Shop1;
		loop m over: informs {
			if (m.contents=informStartAcutionMSG){
				write name + ' Auction started ' + (string(m.contents)+ 'reserve:'+maxPrice);
				step <-1;
			}
		}
	}
	
	reflex receive_cfp_from_initiator when: !empty(cfps)  {
		message proposalFromInitiator<-cfps[0];
		float proposedPrice <-  float( proposalFromInitiator.contents[0]);
		write '(Time ' + time + '): ' + name + ' receives a cfp message from ' + agent(proposalFromInitiator.sender).name + ':'+proposedPrice;
		
		if(proposedPrice>maxPrice){
			write('(Time ' + time + '): ' + name+': price to hig, do refuse (reserve:'+maxPrice+')');
			do refuse message: proposalFromInitiator contents: [refusedProposal] ;	
		}else{
			write('(Time ' + time + '): ' + name+': price good, do accept (reserve:'+maxPrice+')');
			do accept_proposal message: proposalFromInitiator contents: [acceptProposal] ;	
		}
		
	}
	
	
	aspect default{
		draw pyramid(1) at: location color: guestColor;
		draw sphere(0.5) at: location+{0,0,1} color: guestColor;
	}
}

species Initiator skills: [fipa] {
	float initialPrice <- 1000.0;
	float price <- initialPrice;
	float priceStep <-50.0;
	float reserve <-500.0;
	int step <-0;
	int numberBidder <- 0;
	
	bool start_auction <- false;

	reflex startAuction when: (start_auction = false) {
		
		start_auction <- flip(0.005);
		if start_auction{
			write "auction started" color: #red;
			do start_conversation 	to: list(Participant)
		 						protocol: 'fipa-contract-net' 
								performative: 'inform' 
								contents: [ (informStartAcutionMSG)] ;
			step <- 1;
		}
		
		
	}
	
	
	reflex send_cfp_to_participants when: (step = 1) and (length(Participant at_distance 3)=nbOfParticipants) {
		
		write '(Time ' + time + '): ' + name + ' sends a cfp message to all participants:'+price;
		do start_conversation to: list(Participant) protocol: 'fipa-contract-net' performative: 'cfp' contents: [price] ;
		numberBidder <- length(Participant);
		step <- 2;
	}
	
	reflex log_refuses when: !empty(refuses){
		write '(Time ' + time + '): ' + name + ' receives refuse messages';
		write ' step:'+step;
		write refuses;
	}
	
	reflex receive_refuse_messages when:  step=2 and  empty(accept_proposals ) and !empty(refuses ) 
											and ( numberBidder = (length(refuses))){
		write '(Time ' + time + '): ' + name + ' receives refuse messages';
		write 'numberBidder:'+numberBidder;
		write 'length(refuses):'+length(refuses);
		
		if((price-priceStep) > reserve){
			price <- price - priceStep;
			write '(Time ' + time + '): ' + name +"set new price at:"+price;
			write '(Time ' + time + '): ' + name +"send new propose";
			
			//TODO
			loop a_temp_var over: refuses { 
				message refuseFromParticipant<-refuses[0];
		    	do cfp message: refuseFromParticipant contents: [price] ;
		    	
			}
		}else{
			write '(Time ' + time + '): ' + name +" reserved reached, send end_conversation";
			loop a_temp_var over: refuses { 
				message refuseFromParticipant<-a_temp_var;
		    	
				do end_conversation message: refuseFromParticipant contents: [ (informEndAcutionFailedMSG) ] ;
				
			}
		}
		
		
	}
	
	reflex receive_accept_messages when: !empty(accept_proposals ) and step=2 and (empty(refuses) and ((length(accept_proposals) = numberBidder))
										or (numberBidder = (length(accept_proposals)+length(refuses)))) {
		step <- 3;
		
		message firstAccept <- accept_proposals[0];
		
		write '(Time ' + time + '): ' + name + ' receives accepted messages, send end of conversation, winner is'+agent(firstAccept.sender).name ;
		// the first who accept win the auction
		do end_conversation message: firstAccept contents: [ (wonActionMSG)] ;
		
		//the others lose
		loop while: !empty(accept_proposals) {
			message otheAccepts <- accept_proposals[0];
			
			write '(Time ' + time + '): ' + name + ' end of conversation '+agent(otheAccepts.sender).name+' you lost' ;
	    	do end_conversation message: otheAccepts contents:  [lostActionMSG] ;
		}
		loop while: !empty(refuses) {
			message refusesMSG <- refuses[0];
			write '(Time ' + time + '): ' + name + ' end of conversation '+agent(refusesMSG.sender).name+' you lost' ;
	    	do end_conversation message: refusesMSG contents:  [lostActionMSG] ;
		}
		price <- initialPrice;
		start_auction <- false;
		
		ask Participant{
			targetPoint<-EnormousLocation+{rnd(-5,5),rnd(5,-5)};
			busy <- false;
		}

	}
	
	reflex auction_alredy_closed when: step = 3 and (!empty(accept_proposals ) or !empty(refuses )){
		//the others lose
		
		loop while: !empty(accept_proposals) { 
			message otheAccepts <- accept_proposals[0];
			write '(Time ' + time + '): ' + name + ' Auction was already closed,  '+agent(otheAccepts.sender).name+' you lost' ;
	    	do end_conversation message: otheAccepts contents:  [lostActionMSG] ;
		}
		
		loop while: !empty(refuses) { 
			message refusesMSG <- refuses[0];
			write '(Time ' + time + '): ' + name + ' Auction was already closed,  '+agent(refusesMSG.sender).name+' you lost' ;
	    	do end_conversation message: refusesMSG contents:  [lostActionMSG] ;
		}
	}
	
	aspect default{
		draw cube(3) at: location color: #green;
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


species EnormousStage{	
	rgb myColor <- #red;
	
	reflex changeColor {
		myColor <- flip(0.5) ? rnd_color(100, 200) : rnd_color(100, 200);
	}
	
	aspect default{
		draw square(40) at: location color: myColor;
	}
}



experiment Festival type: gui {
	/** Insert here the definition of the input and output of the model */
	output {
		display map type: opengl {
			species Participant;
			species Entrance;
			species Exit;
			species EnormousStage;
			species Initiator;

		}
	}
}
