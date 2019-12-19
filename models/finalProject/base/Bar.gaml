/***
* Name: Bar
* Author: giuliomarcon
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model Bar
import "finalProject_0.gaml"

species Bar skills:[fipa]{
	rgb myColor <- #greenyellow;
	int width <- 20;
	int length <- 10;
	//int height <- 10;
	int height <- 0;
	int minB <- 10;
	int maxB <- 30;

	list<string> beverages  		<- ['Grappa', 'Montenegro', 'Beer', 'Wine','Soda', 'Cola', 'Juice', 'Julmust'];
	list<float> alchoolPercentage 	<- [	0.4, 	0.23, 		0.05, 	0.12,	0.0, 	0.0, 	0.0, 	0.0];
	list<int> beverageSupply		<- [rnd(minB, maxB), rnd(minB, maxB), rnd(minB, maxB), rnd(minB, maxB), 
										rnd(minB, maxB), rnd(minB, maxB), rnd(minB, maxB), rnd(minB, maxB)];
										
//	list<int> beverageSupply		<- [2, 2, 2, 2, 2, 2, 2, 2];
//	list<string> beverages  		<- ['Grappa', 'Montenegro', 'Beer', 'Wine','Soda', 'Cola', 'Juice', 'Julmust'];
//	list<float> alchoolPercentage 	<- [	0.9, 	0.93, 		0.95, 	0.92,	0.9, 	0.9, 	0.9, 	0.9];
//	
	reflex evaluateDrunkness when:!empty(cfps){
		message m<-cfps[0];
		Guest g<-m.sender;
		float userDrunkness <- float(m.contents[0]);
		
		//drunk guest, signal to security
		if(userDrunkness>=drunknesThreshold){
			//write "reporting "+g + "is drunk";
			//write "location of "+g + "is"+g.location;
			do start_conversation to: list(Security) protocol: 'fipa-contract-net' performative: 'inform' contents: [g];
		}
		// guest not drunk, provide menu
		else{
			//write name+" got asked the menu! providing:"+beverages color:#orange;	
			do reply message:m performative:"propose" contents:beverages;
		}
		
	}
	
//	reflex provideMenu when:!empty(cfps){
//		message m<-cfps[0];
//		write name+" message m sender:"+m color:#orange;
//		do reply message:m performative:"propose" contents:beverages;
//		write name+" got asked the menu! providing:"+beverages color:#orange;
//	}
	
	reflex serveDrink when:!empty(accept_proposals){
		message m <- accept_proposals[0];
		int beverageIndex <- int(m.contents[0]);
		
		if (beverageSupply[beverageIndex] > 0){
			do inform message:m contents:[alchoolPercentage[beverageIndex]];
		
			beverageSupply[beverageIndex] <- beverageSupply[beverageIndex] - 1;
			
			if (beverageSupply[beverageIndex] <= 0){
				do start_conversation to: list(Supplier) protocol: 'fipa-contract-net' performative: 'inform' contents: [beverageIndex];
			}
		} else {
			//TODO fix response
			do inform message:m contents:[alchoolPercentage[6]];
		}
		
		
	}
	
	reflex restockBeverages when: !empty(agrees){
		message m <- agrees[0];
		beverageSupply[int(m.contents[0])] <- beverageSupply[int(m.contents[0])] + int(m.contents[1]);
		
		do end_conversation message:m contents:[];
		
	}
	aspect default{
		draw box(width, length, height) at: location color: myColor;
	}
	
	reflex log when: false{
		write beverageSupply color: #red;
	}
}

