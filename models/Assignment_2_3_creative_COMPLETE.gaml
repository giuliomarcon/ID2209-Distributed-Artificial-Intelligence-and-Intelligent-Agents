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
	
	string dusthStartACK <- 'dutch-start-ack';
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
	
	float dutchProbability <-0.005;
	float FPSAProbability <-0.005;
	float japaneseProbability <-0.005;	
	
	list<string> genres <- ['CD','T-Shirt'];
	
	// number of vist at each shop before quitting
	int threshold <- 100;
	
	init{
		
		create InitiatorDutch number: 1{
			location <- Shop1;
			initialPrice<-1000.0;
			priceStep <-50.0;
			reserve<-500.0;
			increasingFactor<-50.0;
		}
		create InitiatorSealedBid number: 1{
			location <- Shop2;
		}
		create InitiatorJapanese number: 1{
			location <- Shop3;
			reserve <- 300.0;
			increasingStep <- 100.0;
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
			location <- EntranceLocation;
			targetPoint<-EnormousLocation+{rnd(-5,5),rnd(5,-5)};
			genre<-rnd(0,length(genres)-1);
			minReserve<-750;
			maxReserve<-950;
		}
		nbOfDutchParticipants <- nbOfDutchParticipants +1;
	}
	
	reflex spawnFPSBAPartecipant when: nOfFPSAPartecipants<totFPSBABidders{
		create PartecipantSealedBid number: 1{
			location <- EntranceLocation;
			targetPoint<-EnormousLocation+{rnd(-5,5),rnd(5,-5)};
			genre<-rnd(0,length(genres)-1);
			esitmatedValue<-1000;
		}
		nOfFPSAPartecipants <- nOfFPSAPartecipants+1;
	}
	
	reflex spawnJapanaesePArtecipant when: nOfJapanesePartecipants<totJapaneseBidders{
		create ParticipantJapanese number: 1{
			location <- EntranceLocation;
			targetPoint<-EnormousLocation+{rnd(-5,5),rnd(5,-5)};
			genre<-rnd(0,length(genres)-1);
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
	int genre;
	
	int step<-0;
			
	reflex beIdle when: targetPoint = nil{
		do wander;
	}
	
	reflex moveToTarget when: targetPoint != nil {
		do goto target:targetPoint;
	}
	

	reflex arrivedToStage when: location distance_to(EnormousLocation) < 5.5 and busy = false {
		targetPoint <- nil;
	}
	
}

species ParticipantDutch parent: Participant{
	rgb guestColor <- #green;
	int maxPrice;
	float lastprice;
	float minReserve;
	float maxReserve;
	
	reflex auctionStarted when: !empty(informs) and step = 0{

		loop m over: informs {
			if (m.contents[0]=informStartAcutionMSG_dutch) and (m.contents[1]=genre){
				maxPrice <-rnd(minReserve,maxReserve);
				do inform message:m contents:[dusthStartACK];
				busy <- true;
				targetPoint <- Shop1;
				lastprice<-0;
				step <-1;
			}
		}
	}
	
	reflex receive_cfp_from_initiator when: !empty(cfps)  {
		message proposalFromInitiator<-cfps[0];
		float proposedPrice <-  float( proposalFromInitiator.contents[0]);
		write '(Time ' + time + '): ' + name + ', dutch,genre:'+genre+' receives a cfp message from ' + agent(proposalFromInitiator.sender).name + ':'+proposedPrice;
		
		if(proposedPrice>maxPrice){
			write('(Time ' + time + '): ' + name + ', dutch,genre:'+genre+': price to hig, do refuse (reserve:'+maxPrice+')');
			do refuse message: proposalFromInitiator contents: [refusedProposal] ;	
		}else{
			lastprice<-proposedPrice;
			write('(Time ' + time + '): ' + name + ', dutch,genre:'+genre+': price good, do accept (reserve:'+maxPrice+')');
			do accept_proposal message: proposalFromInitiator contents: [acceptProposal] ;	
		}
		
	}
	
	reflex won when:!empty(agrees){
		write('(Time ' + time + '): ' + name + ', dutch,genre:'+genre+': I won at:'+lastprice);
		targetPoint<-EnormousLocation+{rnd(-5,5),rnd(5,-5)};
		busy <- false;
		step<-0;
		do end_conversation message: agrees[0] contents: [ (informEndAcutionFailedMSG) ] ;
	}
	reflex lost when:!empty(refuses){
		write('(Time ' + time + '): ' + name + ', dutch, genre:'+genre+': I have lost');
		targetPoint<-EnormousLocation+{rnd(-5,5),rnd(5,-5)};
		busy <- false;
		step <- 0;
		do end_conversation message: refuses[0] contents: [ (informEndAcutionFailedMSG) ] ;
	}
	
	aspect default{
		draw pyramid(1) at: location color: guestColor;
		draw sphere(0.5) at: location+{0,0,1} color: guestColor;
	}
}

species PartecipantSealedBid parent: Participant{
	rgb guestColor <- #yellow;			

	float esitmatedValue;
	float variation<- 0.33;
	float bid;
	message startAuctionMSG ;
	
	reflex auctionStarted when: !empty(informs) and step = 0 {
		busy <- true;
		targetPoint <- Shop2;
		startAuctionMSG <- informs[0];
		
	
		write '(Time ' + time + '): ' +name + ',sealed bid: going to shop ';
	
		if (startAuctionMSG.contents[0]=informStartAcutionMSG_FPSBA){
			step<-1;
		}
	
	}
	
	reflex makeBid when:location distance_to(Shop2) < 2 and step=1{
		bid <- rnd(esitmatedValue*(1-variation),esitmatedValue*(1+variation));
		write ('(Time ' + time + '): ' +name + 'sealed bid:making bid at:'+bid);
		do propose message: startAuctionMSG contents: [bid] ;
		step<-2;	
		
	}
	

	
	reflex wonAuction when:!empty(accept_proposals){
		write ('(Time ' + time + '): ' +name + 'sealed bid:I won the aution making bid at:'+bid+'-'+accept_proposals[0]);
		do end_conversation message: accept_proposals[0] contents: [ (wonActionMSG)] ;
		step<-0;
		remove 0 from: accept_proposals;
	}
	reflex lostAuction when:!empty(reject_proposals ){
		write ('(Time ' + time + '): ' +name + 'sealed bid:I lost the aution making bid at:'+bid+' - '+reject_proposals[0]);
		do end_conversation message: reject_proposals[0] contents: [ (wonActionMSG)] ;
		step<-0;
		remove 0 from:reject_proposals;
		
	}
	aspect default{
		draw pyramid(1) at: location color: guestColor;
		draw sphere(0.5) at: location+{0,0,1} color: guestColor;
	}
	
}

species ParticipantJapanese parent:Participant{
	rgb guestColor <- #blue;
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
			
			write '(Time ' + time + '): ' +name + ', japanese: going to shop at max price'+maxPrice color:#blue;
			do inform message: startAuctionMSG contents: [japaneseStartACK];
		}
	}
	 
	reflex receivedProposal when: !empty(proposes){
		message proposeM <- proposes[0];
		lastProposedPrice<-float(proposeM.contents[0]);
		
		write '(Time ' + time + '): ' + name+', japanese:received proposed '+lastProposedPrice color:#blue;
		if(lastProposedPrice<maxPrice){
			write '(Time ' + time + '): ' +name + ', japanese: accepted' color:#blue;
			do accept_proposal message: proposeM contents:[];
		}else{
			write '(Time ' + time + '): ' +name + ', japanese: rejectd' color:#blue;
			busy<-false;
			targetPoint<-EnormousLocation+{rnd(-5,5),rnd(5,-5)};
			do reject_proposal message: proposeM contents:[];
			step<-0;
		}
	}
	
	
	reflex finishAuction when: !empty(agrees) and step = 0{
		message finishAuctionMSG <- agrees[0];
		write '(Time ' + time + '): ' + name +', japanese: I won the action at price: '+lastProposedPrice;
		do end_conversation message: finishAuctionMSG contents:[];
		busy<-false;
		targetPoint<-EnormousLocation+{rnd(-5,5),rnd(5,-5)};
		step<-0;

		
	}
	
	aspect default{
		draw pyramid(1) at: location color: guestColor;
		draw sphere(0.5) at: location+{0,0,1} color: guestColor;
	}
}

species InitiatorDutch skills: [fipa] {
	float initialPrice;
	float price;
	float priceStep;
	float reserve;
	int step <-0;
	//int numberBidder <- 0;
	int genre;
	int qtySold <-0;
	float increasingFactor<-50.0;
	
	list<message> ack;
	list<ParticipantDutch> bidders;
	
	bool start_auction <- false;
	
	reflex startAuction when: nbOfDutchParticipants>0 and (start_auction = false) and (length(PartecipantSealedBid) = totFPSBABidders) {
		
		start_auction <- flip(dutchProbability);
		if start_auction{
		 	price <- initialPrice;
			reserve<-reserve+qtySold*increasingFactor;
			genre <- flip(0.5) ? 0 : 1;
			write "dutch auction started with genre: "+genre color: #red;
			do start_conversation 	to: list(ParticipantDutch)
		 						protocol: 'fipa-contract-net' 
								performative: 'inform' 
								contents: [ informStartAcutionMSG_dutch, genre] ;
			
		}
		
		
	}
	
	reflex receiveACK when: !empty(informs) and step=0{
		loop m over:informs{
			add m to:ack;
			add m.sender to: bidders;
		}
		step <- 1;
	}
	
	reflex send_cfp_to_participants when: (step = 1) and (length(bidders at_distance 3)=length(bidders)) {
		write '(Time ' + time + '): ' + name + ', dutchInitiator:sends a cfp message to all participants:'+price color: #orange;
		
		loop m over:ack{
			do cfp message:m contents: [price] ;
		}
		step <- 2;
	}
	

	
	reflex receive_refuse_messages when:  step=2 and  empty(accept_proposals ) and !empty(refuses ) 
											and ( length(bidders) = (length(refuses))){
		write '(Time ' + time + '): ' + name + ', dutchInitiator:receives refuse messages from everybody';
		
		if((price-priceStep) > reserve){
			price <- price - priceStep;
			write '(Time ' + time + '): ' + name +"set new price at:"+price;
			
			loop a_temp_var over: refuses { 
				message refuseFromParticipant<-refuses[0];
		    	do cfp message: refuseFromParticipant contents: [price] ;
		    	
			}
		}else{
			write '(Time ' + time + '): ' + name +", dutchInitiator:reserved reached, send end_conversation";
			loop a_temp_var over: refuses { 
				message refuseFromParticipant<-a_temp_var;
		    	
				//do end_conversation message: refuseFromParticipant contents: [ (informEndAcutionFailedMSG) ] ;
				do refuse message: refuseFromParticipant contents:  [informEndAcutionFailedMSG] ;
				qtySold<-qtySold-1;
				price <- initialPrice;
				start_auction <- false;
				step<-0;
				ack<-[];
				bidders<-[];
			}
		}
		
		
	}
	
	reflex receive_accept_messages when: !empty(accept_proposals ) and step=2 and (empty(refuses) and ((length(accept_proposals) = length(bidders)))
										or (length(bidders) = (length(accept_proposals)+length(refuses)))) {
		step <- 3;
		
		message firstAccept <- accept_proposals[0];
		
		write '(Time ' + time + '): ' + name + ', dutchInitiator:receives accepted messages, winner is'+agent(firstAccept.sender).name ;
		// the first who accept win the auction
		do agree message: firstAccept contents: [ (wonActionMSG)] ;
		qtySold<-qtySold+1;
		//the others lose
		loop while: !empty(accept_proposals) {
			message otheAccepts <- accept_proposals[0];
			
			write '(Time ' + time + '): ' + name + ' , dutchInitiator:'+agent(otheAccepts.sender).name+' you lost' ;
	    	do refuse message: otheAccepts contents:  [lostActionMSG] ;
		}
		loop while: !empty(refuses) {
			message refusesMSG <- refuses[0];
			write '(Time ' + time + '): ' + name + ' , dutchInitiator: '+agent(refusesMSG.sender).name+' you lost' ;
	    	do refuse message: refusesMSG contents:  [lostActionMSG] ;
		}
		
		
		price <- initialPrice;
		start_auction <- false;
		step<-0;
		ack<-[];
		bidders<-[];

	}
	
	reflex auction_alredy_closed when: step = 3 and (!empty(accept_proposals ) or !empty(refuses )){
		//the others lose
		
		loop while: !empty(accept_proposals) { 
			message otheAccepts <- accept_proposals[0];
	    	do end_conversation message: otheAccepts contents:  [lostActionMSG] ;
		}
		
		loop while: !empty(refuses) { 
			message refusesMSG <- refuses[0];
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

	reflex startAuction when: (start_auction = false and length(PartecipantSealedBid) = totFPSBABidders) {
		start_auction <- flip(FPSAProbability);
		
		if start_auction{
			write '(Time ' + time + '): ' + name +'SealedBidAuction: Starting new Sealed Bid Auction!'  color:#yellow;
			
			totalBidder <- length(PartecipantSealedBid);
			bids<-nil;
			receivedOffers <- 0;
			bestOffer <- 0.0;
			bestBidMSG <- nil;
					
			do start_conversation 	to: list(PartecipantSealedBid)
			 						protocol: 'fipa-contract-net' 
									performative: 'inform' 
									contents: [ (informStartAcutionMSG_FPSBA)] ;
				
			
			step <- 1;
		}
	
	}
	
	reflex receiveOffers when:!empty(proposes) {
		loop m over: proposes {
			
			add m to: bids;
			
			receivedOffers <- receivedOffers +1;
			float offerValue <- float(m.contents[0]);
			write('(Time ' + time + '): ' + name+'SealedBidAuction:  received:'+m.contents[0]+', from:'+m.sender);
			
			if(bestOffer < offerValue){
				bestOffer <- offerValue;
				bestBidMSG <- m;
			}
		}
	}
	
	reflex reicivingFinished when: (totalBidder = receivedOffers) and step=1{
		write 'reicivingFinished reflex';
		write('(Time ' + time + '): ' + name+'SealedBidAuction:all partecipants have bidded, best offer:'+bestOffer+' from:'+bestBidMSG.sender);
		write('(Time ' + time + '): ' + name+'SealedBidAuction: won:'+bestBidMSG.sender);

		do accept_proposal message: bestBidMSG contents: [ (wonActionMSG)] ;
		
		remove bestBidMSG from: bids;
		loop m over: bids {
			write('(Time ' + time + '): ' + name+'SealedBidAuction:saying to :'+m.sender+' it lost');
			do reject_proposal message: m contents: [ (lostActionMSG)] ;
			
		}
		step <- 0;
		start_auction <- false;
		
		ask PartecipantSealedBid{
			targetPoint<-EnormousLocation+{rnd(-5,5),rnd(5,-5)};
			busy <- false;
		}
		
	}
	

	
	aspect default{
		draw cube(3) at: location color: #yellow;
	}
	
}

species InitiatorJapanese skills: [fipa]{
	float reserve;
	float increasingStep <- 100.0;
	float price;
	int step <- 0;
	
	bool start_auction <- false;
	int totalBidder <- 0;
	list<ParticipantJapanese> activeBidders;
	list<ParticipantJapanese> silentBidders;
	
	reflex startAuction when: (start_auction = false and length(ParticipantJapanese) = totJapaneseBidders) {
		start_auction <- flip(japaneseProbability);
		
		if start_auction{
			write '(Time ' + time + '): ' + name +'japanese:Starting new Japanese Bid Auction!';
			
			write list(ParticipantJapanese) color:#blue;

			do start_conversation 	to: list(ParticipantJapanese)
			 						protocol: 'fipa-contract-net' 
									performative: 'inform' 
									contents: [informStartAcutionMSG_japanese] ;
			activeBidders <- copy(ParticipantJapanese);
			totalBidder <- length(activeBidders);
			
			price <- reserve;
			step <- 1;
		}
	
	}
	
	reflex updatePrice when:(step = 1) and (length(activeBidders at_distance 3)=totalBidder) and !empty(informs) and length(informs)=totalBidder {
		
		write '(Time ' + time + '): ' + name + 'japanese: sends a propose message to all participants with price:'+price;
		price <- price;
		loop m over: informs {
			do propose message: m contents: [price] ;
		}
		step <- 2;
	}
	
	reflex receiveRejection when: !empty(reject_proposals) and step=2{
		loop m over: reject_proposals {
			totalBidder<-totalBidder-1;
			remove m.sender from: activeBidders;
			add m.sender to: silentBidders;
			
			if(length(activeBidders)>=1){
				do end_conversation message: m contents: [] ;
			}else{
				do agree message: m contents: [wonActionMSG];
				start_auction <- false;
				step<-0;
			}
			//make bidder free to go dance
		}
		
	}
	
	reflex receivedAllAcceptance when: !empty(accept_proposals) and totalBidder>=1 and (length(activeBidders)) = totalBidder{
		price <- price + increasingStep;
		loop m over: accept_proposals {
			do propose message: m contents: [price] ;
		}
	}
	
	reflex finishedAuction when: !empty(accept_proposals) and (length(silentBidders)+1) = totJapaneseBidders{
		do inform message: accept_proposals[0] contents: [wonActionMSG];
		start_auction <- false;
		step<-0;
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
			species ParticipantJapanese;
			species InitiatorDutch;
			species InitiatorSealedBid;
			species InitiatorJapanese;
			species Entrance;
			species Exit;
			species EnormousStage;
		}
	}
}
