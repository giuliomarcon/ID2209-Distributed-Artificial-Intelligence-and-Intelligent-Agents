/***
* Name: Assignment30task2
* Author: Nico Catalano
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model Assignment30task2

/* Insert your model definition here */

global {
	int durationAct <- 100;
	int timeCounter<-0;
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
	float crowdMass;
	bool dressCode;
	int stageIndex;
	bool smoke;
	
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
		
		crowdMass<-rnd(minL, maxL);
		
		pref0<- -1.0;
		pref1<- -1.0;
		pref2<- -1.0;
		pref3<- -1.0;
		preferredStage <- -1;
		walking<-false;
	}
	
	reflex receivedNewAct when:!empty(informs){
		message m <- informs[0];
		
		write name+ " received inform message!";
		
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
		
		
		
		
		
	}
	
	reflex gotAllPref when:(pref0>0 and pref1>0 and pref2>0 and pref3>0){
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
		pref0<- -1.0;
		pref1<- -1.0;
		pref2<- -1.0;
		pref3<- -1.0;
		
		write name+" goingTo "+preferredStage color:#red;
		walking<-true;
		
		targetPoint<-stageLocations[preferredStage];
		
		 
		do start_conversation to: list(leaders[0]) protocol: 'fipa-contract-net' performative: 'inform' contents: [selectedValue] ;
	}

	reflex moveToTarget when: targetPoint != nil {
		do goto target:targetPoint;
	}
	
	reflex arrivedStage when: targetPoint!= nil and location distance_to(targetPoint) < 1{
		walking<-false;
		targetPoint<-nil;
	}
	
	reflex dance when: walking=false{
		do wander;
	}
	
    aspect default{
       	draw cone3D(1.3,2.3) at: location color: #slategray ;
    	draw sphere(0.7) at: location + {0, 0, 2} color: #salmon ;
    }
    
}

	
species Leader skills:[fipa]{
	int msgReceivedCount<-0;
	float globalUtility<-0;
	//TODO quando lo resetti?
	list<int> guestCounter<-[0,0,0,0];
	
	reflex receivedPreference when:length(informs)>0 and msgReceivedCount<totalGuests{
		loop m over: informs{
			msgReceivedCount<-msgReceivedCount+1;
			globalUtility<-globalUtility+float(m.contents[0]);
			
		}
		
	}
	
	reflex allMsgReceived when: msgReceivedCount=totalGuests{
		write "got max global utility:"+globalUtility color:#red;
		msgReceivedCount<-0;
		globalUtility<-0;
	}
}


experiment Festival type: gui {
	/** Insert here the definition of the input and output of the model */
	output {
		display map type: opengl {
			species Stage;
			species Guest;
		}
	}
}
