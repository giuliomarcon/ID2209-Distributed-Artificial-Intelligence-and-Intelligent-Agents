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
	point Shop2 <- {30, 10};
	point Shop3 <- {40, 10};

	
	string informStartAcutionMSG_dutch <- 'inform-start-of-auction-dutch';
	string informStartAcutionMSG_FPSBA <- 'inform-start-of-auction-first-price-saled-bid';
	string informStartAcutionMSG_japanese <- 'inform-start-of-auction-japanese';
	
	string japaneseStartACK <- 'japanese-start-ack';
	
	string informEndAcutionFailedMSG <- 'auction-failed';
	string wonActionMSG <- 'won-auction';
	string lostActionMSG <- 'lost-auction';
	string acceptProposal <-'accepted-proposal';
	string refusedProposal <-'rejected-proposal';
	
	
	int nbOfDutchParticipants <- 0;
	int nOfFPSAPartecipants <- 0;
	int nOfJapanesePartecipants <- 0;
	
	int totDutchBidders <- 5;
	int totFPSBABidders <- 5;
	int totJapaneseBidders <- 5;
	
	// number of vist at each shop before quitting
	int threshold <- 100;
	
	init{
		
		create InitiatorDutch number: 1{
			location <- Shop1;
		}
		create InitiatorSealedBid number: 1{
			location <- Shop2;
		}
		create InitiatorJapanese number: 1{
			location <- Shop3;
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

	reflex spawnDutchPartecipant when: nbOfDutchParticipants<totDutchBidders{
		create ParticipantDutch number: 1{
			write "created Dutch partecipant";
			location <- EntranceLocation;
			targetPoint<-EnormousLocation+{rnd(-5,5),rnd(5,-5)};
		}
		nbOfDutchParticipants <- nbOfDutchParticipants +1;
	}
	
	reflex spawnFPSBAPartecipant when: nOfFPSAPartecipants<totFPSBABidders{
		create PartecipantSealedBid number: 1{
			write "created FPSBA partecipant";
			location <- EntranceLocation;
			targetPoint<-EnormousLocation+{rnd(-5,5),rnd(5,-5)};
			
		}
		nOfFPSAPartecipants <- nOfFPSAPartecipants+1;
	}
	
	reflex spawnJapanaesePArtecipant when: nOfJapanesePartecipants<totJapaneseBidders{
		create PartecipantJapanese number: 1{
			write "created japanese partecipant";
			location <- EntranceLocation;
			targetPoint<-EnormousLocation+{rnd(-5,5),rnd(5,-5)};
			
		}
		nOfJapanesePartecipants <- nOfJapanesePartecipants+1;
		
	}
	
	reflex globalPrint{
		//write "Step od simulation: " +time ;
	}
}

species Participant skills:[moving,fipa]{
	point targetPoint <- nil;
	bool busy <- false;
	
	int step<-0;
			
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
	
}

species ParticipantDutch parent: Participant{
	rgb guestColor <- #green;
	int maxPrice <-rnd(750,950);
	
	// TODO fix
	reflex auctionStarted when: !empty(informs) and step = 0{
		busy <- true;
		targetPoint <- Shop1;
		loop m over: informs {
			if (m.contents=informStartAcutionMSG_dutch){
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

species PartecipantSealedBid parent: Participant{
	rgb guestColor <- #yellow;			

	float esitmatedValue<- 1000.0;
	float variation<- 0.33;
	float bid;
	message startAuctionMSG ;
	reflex log when:false{
		write ('(Time ' + time + '): ' +name + ' LOG:');
		write ('accept_proposals ('+length(accept_proposals ));
		write ('agrees  ('+length(agrees  ));
		write ('cancels  ('+length(cancels  ));
		write ('cfps  ('+length(cfps  ));
		write ('conversations  ('+length(conversations  ));
		write ('failures  ('+length(failures  ));
		write ('informs   ('+length(informs   ));
		write ('proposes   ('+length(proposes   ));
		write ('queries   ('+length(queries   ));
		write ('refuses   ('+length(refuses   ));
		write ('failures  ('+length(failures  ));
		write ('reject_proposals   ('+length(reject_proposals   ));
		write ('requests   ('+length(requests   ));
		write ('requestWhens   ('+length(requestWhens   ));
		write ('subscribes   ('+length(subscribes   ));
	}

	
	//reflex auctionStarted when: !empty(informs) and step = 0{
	reflex auctionStarted when: !empty(informs) and step = 0 {
		busy <- true;
		targetPoint <- Shop2;
		startAuctionMSG <- informs[0];
		
	
		write '(Time ' + time + '): ' +name + ': going to shop ';
	
		if (startAuctionMSG.contents[0]=informStartAcutionMSG_FPSBA){
			step<-1;
		}
	
	}
	
	reflex makeBid when:location distance_to(Shop2) < 2 and step=1{
		bid <- rnd(esitmatedValue*(1-variation),esitmatedValue*(1+variation));
		write ('(Time ' + time + '): ' +name + ' making bid at:'+bid);
		do propose message: startAuctionMSG contents: [bid] ;
		step<-2;	
		
	}
	

	
	reflex wonAuction when:!empty(accept_proposals){
		write ('(Time ' + time + '): ' +name + ' I won the aution making bid at:'+bid+'-'+accept_proposals[0]);
		do end_conversation message: accept_proposals[0] contents: [ (wonActionMSG)] ;
		step<-0;
		remove 0 from: accept_proposals;
		write 'acceptance:'+accept_proposals;
	}
	reflex lostAuction when:!empty(reject_proposals ){
		write ('(Time ' + time + '): ' +name + ' I lost the aution making bid at:'+bid+' - '+reject_proposals[0]);
		do end_conversation message: reject_proposals[0] contents: [ (wonActionMSG)] ;
		step<-0;
		remove 0 from:reject_proposals;
		write 'rejected:'+reject_proposals;
		
	}
	aspect default{
		draw pyramid(1) at: location color: guestColor;
		draw sphere(0.5) at: location+{0,0,1} color: guestColor;
	}
	
}

species PartecipantJapanese parent:Participant{
	float avgMaxPrice <- 800.0;
	float varianceMaxPrice <- 75.0;
	float lastProposedPrice;
	float maxPrice;
	
	reflex startAuction when: !empty(informs) and step = 0{
		busy <- true;
		targetPoint <- Shop3;
		message startAuctionMSG <- informs[0];
		lastProposedPrice<-0.0;
	
	
		if (startAuctionMSG.contents[0]=informStartAcutionMSG_japanese){
			step<-1;
			maxPrice<-rnd(avgMaxPrice-varianceMaxPrice,avgMaxPrice+varianceMaxPrice);
			
			write '(Time ' + time + '): ' +name + ': going to shop at max price'+maxPrice color:#blue;
			do inform message: startAuctionMSG contents: [japaneseStartACK];
		}
	}
	 
	reflex receivedProposal when: !empty(proposes){
		message proposeM <- proposes[0];
		lastProposedPrice<-float(proposeM.contents[0]);
		
		write '(Time ' + time + '): ' + name+'received proposed '+lastProposedPrice color:#blue;
		if(lastProposedPrice<maxPrice){
			do accept_proposal message: proposeM contents:[];
		}else{
			write '(Time ' + time + '): ' +name + ': rejectd' color:#blue;
			busy<-false;
			targetPoint <- Shop3;
			do reject_proposal message: proposeM contents:[];
		}
	}
	
	
	reflex finishAuction when: !empty(informs) and step = 1{
		message finishAuctionMSG <- informs[0];
		write '(Time ' + time + '): ' + name +': I won the action at price: '+lastProposedPrice;
		do end_conversation message: finishAuctionMSG contents:[];
		step<-0;
	}
}

species InitiatorDutch skills: [fipa] {
	float initialPrice <- 1000.0;
	float price <- initialPrice;
	float priceStep <-50.0;
	float reserve <-500.0;
	int step <-0;
	int numberBidder <- 0;
	
	
	bool start_auction <- false;
	
	//TODO check all the partecipat are spawned
	reflex startAuction when: nbOfDutchParticipants>0 and (start_auction = false) {
		
		start_auction <- flip(0);
		if start_auction{
			write "dutch auction started" color: #red;
			do start_conversation 	to: list(ParticipantDutch)
		 						protocol: 'fipa-contract-net' 
								performative: 'inform' 
								contents: [ (informStartAcutionMSG_dutch)] ;
			step <- 1;
		}
		
		
	}
	
	
	reflex send_cfp_to_participants when: (step = 1) and (length(ParticipantDutch at_distance 3)=nbOfDutchParticipants) {
		
		write '(Time ' + time + '): ' + name + ' sends a cfp message to all participants:'+price;
		do start_conversation to: list(ParticipantDutch) protocol: 'fipa-contract-net' performative: 'cfp' contents: [price] ;
		numberBidder <- length(ParticipantDutch);
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
		
		ask ParticipantDutch{
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


species InitiatorSealedBid skills:[fipa]{
	bool start_auction <- false;
	int step <- 0;
	
	list<message> bids;
	
	int totalBidder <- 0;
	int receivedOffers <- 0;
	float bestOffer <- 0.0;
	message bestBidMSG <- nil;
//	
//	reflex logINFO when: !empty(informs) {
//		write "##### log informs"+informs;
//	}
//	
//	reflex logPROPOSE when: !empty(proposes) {
//		write "##### log propose"+proposes;
//	}
//	
	reflex startAuction when: (start_auction = false and length(PartecipantSealedBid) = totFPSBABidders) {
		start_auction <- flip(0);
		
		if start_auction{
			write '(Time ' + time + '): ' + name +'Starting new Saled Bid Auction! to('+length(PartecipantSealedBid)+')'+PartecipantSealedBid color:#yellow;
			
			totalBidder <- length(PartecipantSealedBid);
			bids<-nil;
			receivedOffers <- 0;
			bestOffer <- 0.0;
			bestBidMSG <- nil;
					
//			do start_conversation 	to: list(PartecipantSaledBid)
//		 						protocol: 'fipa-contract-net' 
//								performative: 'inform' 
//								contents: [ (informStartAcutionMSG_FPSBA)] ;

			do start_conversation 	to: list(PartecipantSealedBid)
			 						protocol: 'fipa-contract-net' 
									performative: 'inform' 
									contents: [ (informStartAcutionMSG_FPSBA)] ;
				
			
			step <- 1;
		}
	
	}
	
	reflex receiveOffers when:!empty(proposes) {//and step=1 {
		write 'receiveOffers reflex';
		loop m over: proposes {
			
			add m to: bids;
			
			receivedOffers <- receivedOffers +1;
			float offerValue <- float(m.contents[0]);
			write('(Time ' + time + '): ' + name+': received '+m.contents[0]);
			
			if(bestOffer < offerValue){
				bestOffer <- offerValue;
				bestBidMSG <- m;
			}
		}
	}
	
	reflex reicivingFinished when: (totalBidder = receivedOffers) and step=1{
		write 'reicivingFinished reflex';
		write('(Time ' + time + '): ' + name+':all partecipants have bidded, best offer:'+bestOffer+' from:'+bestBidMSG.sender);
		write('(Time ' + time + '): ' + name+':sayng to'+bestBidMSG.sender+'it won');
		write('(Time ' + time + '): bestBidMSG:'+bestBidMSG);
		//do accept_proposal message: bestBidMSG contents: [ (wonActionMSG)] ;
		do accept_proposal message: bestBidMSG contents: [ (wonActionMSG)] ;
		//do end_conversation message: bestBidMSG contents: [ (wonActionMSG)] ;
		
		remove bestBidMSG from: bids;
		loop m over: bids {
			write('(Time ' + time + '): ' + name+':saying to :'+m.sender+' it lost');
			do reject_proposal message: m contents: [ (lostActionMSG)] ;
		//	do end_conversation message: m contents: [ (lostActionMSG)] ;
			
		}
		step <- 0;
		start_auction <- false;
		
		ask PartecipantSealedBid{
			targetPoint<-EnormousLocation+{rnd(-5,5),rnd(5,-5)};
			busy <- false;
		}
		
	}
	
//	reflex restartAuction when: (step = 2){
//		write 'restartAuction reflex';
//		bool restart_auction <- flip(0.005);
//		if restart_auction{
//			step <- 0;
//		}
//	}
	
	aspect default{
		draw cube(3) at: location color: #yellow;
	}
	
}

species InitiatorJapanese skills: [fipa]{
	float reserve <- 300.0;
	float increasingStep <- 10.0;
	float price;
	
	bool start_auction <- false;
	int totalBidder <- 0;
	list<PartecipantJapanese> activeBidders;
	list<PartecipantJapanese> silentBidders;
	
	reflex startAuction when: (start_auction = false and length(PartecipantJapanese) = totJapaneseBidders) {
		start_auction <- flip(0.005);
		
		if start_auction{
			write '(Time ' + time + '): ' + name +'Starting new Japanese Bid Auction! to('+length(PartecipantJapanese)+')'+PartecipantJapanese color:#blue;
			write '(Time ' + time + '): ' + name +'reserve:'+reserve color:#blue;
			
			write list(PartecipantJapanese) color:#blue;

			do start_conversation 	to: list(PartecipantJapanese)
			 						protocol: 'fipa-contract-net' 
									performative: 'inform' 
									contents: [informStartAcutionMSG_japanese] ;
			activeBidders <- copy(PartecipantJapanese);
			totalBidder <- length(activeBidders);
			
			price <- reserve;
			step <- 1;
		}
	
	}
	
	reflex updatePrice when:(step = 1) and (length(activeBidders at_distance 3)=totalBidder) and !empty(informs) and length(informs)=totalBidder {
		
		write '(Time ' + time + '): ' + name + ' sends a propose message to all participants:'+price;
		price <- price;
		loop m over: informs {
			write '(Time ' + time + '): ' + name +' informing :'+m.sender+' the riserve price:'+reserve color:#blue;
			do propose message: m contents: [price] ;
		}
		step <- 2;
	}
	
	reflex receiveRejection when: !empty(reject_proposals) and step=2{
		loop m over: reject_proposals {
			totalBidder<-totalBidder-1;
			remove m.sender from: activeBidders;
			add m.sender to: silentBidders;
			do end_conversation message: m contents: [] ;
			//make bidder free to go dance
		}
		
	}
	
	reflex receivedAllAcceptance when: !empty(accept_proposals) and totalBidder>1 and (length(activeBidders)) = totalBidder{
		price <- price + increasingStep;
		loop m over: accept_proposals {
			do propose message: m contents: [price] ;
		}
	}
	
	reflex finishedAuction when: ! empty(accept_proposals) and (length(silentBidders)+1) = totJapaneseBidders{
		do inform message: accept_proposals[0] contents: [wonActionMSG];
	}
	
	aspect default{
		draw cube(3) at: location color: #blue;
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
			species ParticipantDutch;
			species PartecipantSealedBid;
			species PartecipantJapanese;
			species InitiatorDutch;
			species InitiatorSealedBid;
			species InitiatorJapanese;
			species Entrance;
			species Exit;
			species EnormousStage;
		}
	}
}
