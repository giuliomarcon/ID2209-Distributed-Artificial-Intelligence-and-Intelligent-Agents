/***
* Name: Assignment30task2
* Author: Nico Catalano
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model Assignment30task2

/* Insert your model definition here */

global {
	int durationAct <- 500;
	int timeCounter<--10;
	//int totalGuests<-10;
	int totalGuests<-10;
	list<point> stageLocations <- [{10,10},{90,10},{90,90},{10,90}];
	
	float minL <-0.0;
	float maxL <-1.0;
	
	init{
		create Stage number: 1 {
			stageIndex<-0;
			location <- stageLocations[0];
		}
		
		create Stage number: 1 {
			stageIndex<-1;
			location <- stageLocations[1];
		}
		
		create Stage number: 1 {
			stageIndex<-2;
			location <- stageLocations[2];
		}
		
		create Stage number: 1 {
			stageIndex<-3;
			location <- stageLocations[3];
		}
		create Guest number: totalGuests {
			location <- {rnd(50-10,50+10),rnd(50-10,50+10)};
		}
		create Leader;
		
	}
	
	reflex updateTime {
		if(timeCounter= durationAct){
			timeCounter <- -1;
		}
		timeCounter<-timeCounter +1;
	}
}



species Stage skills:[fipa]{
	rgb myColor <- #red;
	float light;
	float speakers;
	float band;
	float aesthetic;
	bool dressCode;
	int stageIndex;

	bool smoke;
	
	reflex changeAct when:(timeCounter)=0{
		light<-rnd(minL, maxL);
		speakers<-rnd(minL, maxL);
		band<-rnd(minL, maxL);
		aesthetic<-rnd(minL, maxL);
		dressCode<-flip(0.5);
		smoke<-flip(0.5);
		//advertise new act
//		write "****************************";
		do start_conversation to: list(Guest) protocol: 'fipa-contract-net' performative: 'inform' contents: [stageIndex,light,speakers,band,aesthetic,dressCode,smoke] ;
	}
	
	reflex changeColor {
		myColor <- flip(0.5) ? rnd_color(100, 200) : rnd_color(100, 200);
	}
	
	aspect default{
		draw square(20) at: location color: myColor;
	}

}


species Guest skills:[fipa, moving]{
	float light;
	float speakers;
	float band;
	float aesthetic;
	bool crowdMass;
	bool dressCode;
	int stageIndex;
	bool smoke;
	
	int status;
	list<float> utilities<-[0,0,0,0];
	
	float pref0;
	float pref1;
	float pref2;
	float pref3;
	
	int preferredStage;
	
	point targetPoint <- nil;
	bool walking;
	
	init{
		light<-rnd(minL, maxL);
		speakers<-rnd(minL, maxL);
		band<-rnd(minL, maxL);
		aesthetic<-rnd(minL, maxL);
		dressCode<-flip(0.5);
		smoke<-flip(0.5);
		//false whant to be alone, true whant to be in crowded areas
		crowdMass<-flip(0.5);
		
		pref0<- -1.0;
		pref1<- -1.0;
		pref2<- -1.0;
		pref3<- -1.0;
		preferredStage <- -1;
		walking<-false;
		
		status<-0;
	}
	
	reflex receivedNewAct when:!empty(informs) and !(string(informs[0].sender) contains "Lead"){
		message m <- informs[0];
		
		write name+ " received inform message from:"+m.sender;
		write "status:"+status;
		
		float pValue <-  float(m.contents[1])*light+ float(m.contents[2])*speakers+float(m.contents[3])*band+float(m.contents[4])*aesthetic;
		
		if(smoke = bool(m.contents[6])){
			pValue<-pValue*1.1;
		}
		
		if(dressCode = bool(m.contents[5])){
			pValue<-pValue*1.1;
		}
		
		if(m.contents[0]=0){
			pref0<-pValue;
		}else if(m.contents[0]=1){
			pref1<-pValue;
		}else if(m.contents[0]=2){
			pref2<-pValue;
		}else if(m.contents[0]=3){
			pref3<-pValue;
		}
		
		
		status<-1;
		
		
	}
	
	reflex gotAllPref when:(pref0>0 and pref1>0 and pref2>0 and pref3>0) and status =1{
		list<Leader> leaders <- list(Leader);
		write name+" pref0:"+pref0 color:#red;
		write name+" pref1:"+pref1 color:#red;
		write name+" pref2:"+pref2 color:#red;
		write name+" pref3:"+pref3 color:#red;
		
		float selectedValue <- max([pref0,pref1,pref2,pref3]);
		
		if(selectedValue=pref0){
			preferredStage<-0;
		}else if(selectedValue=pref1){
			preferredStage<-1;
		}else if(selectedValue=pref2){
			preferredStage<-2;
		}else if(selectedValue=pref3){
			preferredStage<-3;
		}
		
		utilities[0]<-pref0;
		utilities[1]<-pref1;
		utilities[2]<-pref2;
		utilities[3]<-pref3;
		pref0<- -1.0;
		pref1<- -1.0;
		pref2<- -1.0;
		pref3<- -1.0;
		
		write name+" goingTo "+preferredStage color:#red;
		walking<-true;
		
		targetPoint<-stageLocations[preferredStage];
		
		 
		do start_conversation to: list(leaders[0]) protocol: 'fipa-contract-net' performative: 'inform' contents: [selectedValue,preferredStage] ;
		write ""+name+" preferredStage:"+preferredStage;
		status<-2;
	}

	reflex askHowCrowded when:status = 4 and !walking{
		list<Leader> leaders <- list(Leader);
		do start_conversation to: list(leaders[0]) protocol: 'fipa-contract-net' performative: 'query' contents: [''] ;
		status<-5;
	}
	
	reflex decideIfMove when:status = 5 and !empty(informs) and !walking{
		message m<-informs[0];
		list<int> guestCounter<-m.contents;
		int desiredStage;
		list<Leader> leaders <- list(Leader);
		
		write "got accupancylist:"+guestCounter color:#green;
		write "we are:"+guestCounter[preferredStage]+ " at "+preferredStage color:#green;
		
		// want to be alone
		if(crowdMass=false and guestCounter[preferredStage]>1 and min(guestCounter)<guestCounter[preferredStage]){
			desiredStage<-index_of(guestCounter,min(guestCounter));
			write "I want to be alore,want to go to"+index_of(guestCounter,min(guestCounter)) color:#orange;
		}//else if (  max(guestCounter)>guestCounter[preferredStage]){
		else{
			desiredStage<-index_of(guestCounter,max(guestCounter));
			write "I DO NOT want to be alore,want to go to"+index_of(guestCounter,max(guestCounter)) color:#orange;
		}
		
		do start_conversation to: list(leaders[0]) protocol: 'fipa-contract-net' performative: 'propose' contents: [desiredStage,utilities[desiredStage],preferredStage] ;
		status<-5;
	}
	
	reflex gotResponse when:!empty(accept_proposals) and !walking{
		message m<-accept_proposals[0];
		int newStage<-int(m.contents[0]);
		preferredStage<-newStage;
		targetPoint<-stageLocations[preferredStage];
		walking<-true;		
		do end_conversation message: m contents: [ ('') ] ;
		
	}

	reflex moveToTarget when: targetPoint != nil {
		do goto target:targetPoint;
		status<-3;
	}
	
	reflex arrivedStage when: targetPoint!= nil and location distance_to(targetPoint) < 1{
		walking<-false;
		targetPoint<-nil;
		status<-4;
	}
	
	reflex dance when: walking=false{
		do wander;
	}
	
    aspect default{
       	//draw cone3D(1.3,2.3) at: location color: #slategray ;
    	//draw sphere(0.7) at: location + {0, 0, 2} color: #salmon ;
    	
    	if(crowdMass){
			// 	want to be with people
	       	draw cone3D(1.3,2.3) at: location color: #red ;
	    	draw sphere(0.7) at: location + {0, 0, 2} color: #red ;
    	}else{
			// want to be alone
	       	draw cone3D(1.3,2.3) at: location color: #blue ;
	    	draw sphere(0.7) at: location + {0, 0, 2} color: #blue ;
    	}
    }
    
}

	
species Leader skills:[fipa]{
	int msgReceivedCount<-0;
	float globalUtility<-0;
	//TODO quando lo resetti?
	list<int> guestCounter<-[0,0,0,0];
	list<float> guestUtility<-[0,0,0,0];
	
	reflex receivedPreference when:length(informs)>0 and msgReceivedCount<totalGuests{
		loop m over: informs{
			msgReceivedCount<-msgReceivedCount+1;
			guestUtility[int(m.contents[1])]<-float(m.contents[0]);
			int stageIndex<-int(m.contents[1]);
			guestCounter[stageIndex]<-guestCounter[stageIndex]+1;
			
		}
		
	}
	
	reflex allMsgReceived when: msgReceivedCount=totalGuests{
		globalUtility<-sum(guestUtility);
		write "got max global utility:"+globalUtility color:#red;
		msgReceivedCount<-0;
		//globalUtility<-0;
	}
	
	reflex replyHowCrowded when:!empty(queries){
		message m <- queries[0];
		write ""+name+"providing guestCounter:"+guestCounter color:#pink;
		do inform message:m contents:guestCounter;
	}
	
	reflex replyProposeChange when:!empty(proposes){
		message m <- proposes[0];
		int originalStage <- m.contents[2];
		int desiredStage <- m.contents[0];
		float newUtil<-m.contents[1];
		list<float> guestUtilityTmp<- copy(guestUtility);
		
		guestUtilityTmp[desiredStage]<-newUtil;
		
		float newGlobalUtility<-sum(guestUtilityTmp);
		
		write "globalUtility:"+globalUtility color:#red;
		write  "newGlobalUtility:"+newGlobalUtility color:#red;
		
		if(newGlobalUtility>=globalUtility){
			write "tell "+m.sender+" to move to "+desiredStage color:#orange;
			guestCounter[originalStage]<-guestCounter[originalStage]-1;
			guestCounter[desiredStage]<-guestCounter[desiredStage]+1;
			guestUtility<-copy(guestUtilityTmp);
			globalUtility<-newGlobalUtility;
//			write globalUtility;
			
			do accept_proposal message: m contents:[desiredStage];
		}else{
			write ""+m.sender+" stay in place at "+originalStage color:#orange;
			do accept_proposal message: m contents:[originalStage];
		}
	
	}
	
}


experiment Festival type: gui {
	/** Insert here the definition of the input and output of the model */
	output {
		display map type: opengl {
			species Stage;
			species Guest;
			species Leader;
		}
	}
}
