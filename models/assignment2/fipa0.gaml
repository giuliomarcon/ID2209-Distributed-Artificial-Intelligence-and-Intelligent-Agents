/**
* Name: FIPA Contract Net
* Author:
* Description: This model demonstrates a use-case of the FIPA Contract Net interaction protocol. 
* One initiator sends a 'cfp' message to other participants. 
* All participants reply with a 'refuse' messages which end the interaction protocol.
* Tags: fipa
*/

model cfp_cfp_1

global {
	string informStartAcutionMSG <- 'inform-start-of-auction';
	string informEndAcutionFailedMSG <- 'auction-failed';
	string wonActionMSG <- 'won-auction';
	string lostActionMSG <- 'lost-auction';
	string acceptProposal <-'accepted-proposal';
	string refusedProposal <-'rejected-proposal';
	int nbOfParticipants <- 3;
	
	init {
		create Initiator;
		create Participant number: nbOfParticipants;
		
		write 'Step the simulation to observe the outcome in the console';
	}
}

species Initiator skills: [fipa] {
	float price <- 1000.0;
	float priceStep <-50.0;
	float reserve <-500.0;
	int step <-0;


	reflex startAuction when: (step = 0) {
		do start_conversation 	to: list(Participant)
		 						protocol: 'fipa-contract-net' 
								performative: 'inform' 
								contents: [ (informStartAcutionMSG)] ;
		step <- 1;
	}
	
	
	reflex send_cfp_to_participants when: (step = 1) {
		
		write '(Time ' + time + '): ' + name + ' sends a cfp message to all participants:'+price;
		do start_conversation to: list(Participant) protocol: 'fipa-contract-net' performative: 'cfp' contents: [price] ;
		step <- 2;
	}
	
	
	reflex receive_refuse_messages when:  empty(accept_proposals ) and !empty(refuses ) and step=2 {
		write '(Time ' + time + '): ' + name + ' receives refuse messages';
		
				
		write refuses;
		if((price-priceStep) > reserve){
			price <- price - priceStep;
			write '(Time ' + time + '): ' + name +"set new price at:"+price;
			write '(Time ' + time + '): ' + name +"send new propose";
			
			//TODO
			loop a_temp_var over: refuses { 
				message refuseFromPartecipant<-refuses[0];
		    	do cfp message: refuseFromPartecipant contents: [price] ;
			}
		}else{
			write '(Time ' + time + '): ' + name +" reserved reached, send end_conversation";
			loop a_temp_var over: refuses { 
				message refuseFromPartecipant<-refuses[0];
		    	message tmp<-refuses[0];
		    	
				do end_conversation message: refuseFromPartecipant contents: [ (informEndAcutionFailedMSG) ] ;
			}
		}
		write refuses;
	}
	
	reflex receive_accept_messages when: !empty(accept_proposals ) and step=2 {
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
	
}

species Participant skills: [fipa] {
	int step<-0;
	int maxPrice <-rnd(750,950);
	
	// TODO fix
	reflex auctionStarted when: !empty(informs) and step = 0{
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

}

experiment test_no_protocol type: gui {}