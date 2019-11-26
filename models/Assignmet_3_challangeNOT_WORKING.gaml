/***
* Name: Assignment30task2
* Author: Nico Catalano
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model Assignment30task2

/* Insert your model definition here */

global {
	//int durationAct <- 100;
	int durationAct <- 10000;
	int timeCounter<--10;
	int totalGuests<-10;
	list<point> stageLocations <- [{10,10},{90,10},{90,90},{10,90}];
	
	float minL <-0.0;
	float maxL <-1.0;
	
	init{
		create Leader number:1;
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
		crowdMass<-rnd(minL, maxL);
		dressCode<-flip(0.5);
		smoke<-flip(0.5);
		

		
		pref0<- -1.0;
		pref1<- -1.0;
		pref2<- -1.0;
		pref3<- -1.0;
		preferredStage <- -1;
		walking<-false;
	}
	
	reflex receivedNewAct when:!empty(informs){
		
		message m <- informs[0];
		
		do end_conversation message: m contents: [ ('') ] ;
		
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
	
	reflex gotAllPref when:(pref0>0 and pref1>0 and pref2>0 and pref3>0 ){
//		write name+" pref0:"+pref0 color:#red;
//		write name+" pref1:"+pref1 color:#red;
//		write name+" pref2:"+pref2 color:#red;
//		write name+" pref3:"+pref3 color:#red;
//		write name+" crowdMass:"+crowdMass color:#red;
		list<Leader> leaders <- list(Leader);
		 
		do start_conversation to: list(leaders[0]) protocol: 'fipa-contract-net' performative: 'inform' contents: [pref0,pref1,pref2,pref3,crowdMass] ;
		
/* 		float selectedValue <- max([pref0,pref1,pref2,pref3]);	
		if(selectedValue=pref0){
			preferredStage<-0;
		}else if(selectedValue=pref1){
			preferredStage<-1;
		}else if(selectedValue=pref2){
			preferredStage<-2;
		}else if(selectedValue=pref3){
			preferredStage<-3;
		}
		* 
		*/
		pref0<- -1.0;
		pref1<- -1.0;
		pref2<- -1.0;
		pref3<- -1.0;
		
/*		write name+" goingTo "+preferredStage color:#red;
		walking<-true;
		targetPoint<-stageLocations[preferredStage];
		
*/
	}
	
	reflex gotDestination when:!empty(proposes){
		message m<-proposes[0];
		walking<-true;
		write "message received from "+m.sender;
		write "going to:"+(m.contents[0]);
		targetPoint<-stageLocations[int(m.contents[0])];
		do end_conversation message: m contents: [ ('') ] ;
		
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
	list<TreeLeaf> nodes <- [];
	graph decisionsGraph <- graph([]);
	int msgReceivedCount<-0;
	species SelectedStage {
	    int stage <- 0;// max:4 min:1;
	    Guest subject<-nil;
	}
	
	species TreeLeaf{
		list<SelectedStage> stageAssigned<-[];
		float totalProfit<-0.0;
	}
	
	
	
	reflex receivedPreference when:length(informs)>0 and msgReceivedCount<totalGuests{
		loop m over: informs{
			msgReceivedCount<-msgReceivedCount+1;
			float partialProfit<-float(m.contents[0])+float(m.contents[1])+float(m.contents[2])+float(m.contents[3]);
			
			SelectedStage toStage1;
		 	toStage1.stage<-1;
		 	toStage1.subject<-m.sender;
		 	
		 	if(length(decisionsGraph)=0){
			 	create TreeLeaf returns:ln;
			 	TreeLeaf l0 <- ln[0];
			 				 	
			 	decisionsGraph <- decisionsGraph add_node(l0);
		 	}
		 	
	 		list<TreeLeaf> bottomLevel<-[];
	 		
	 		loop nod over: decisionsGraph.vertices{
	 			if(decisionsGraph degree_of nod<=1){
	 				add nod to:bottomLevel;
	 			}
			}
			
			loop leaf over:bottomLevel{
				list<float> profits;
				list<TreeLeaf> newLeafs;
				
				float lowestProfit;
				TreeLeaf lowestLeaf;
				
				loop i from: 1 to:  4 { 
					create TreeLeaf returns:ln;
				 	TreeLeaf l <- ln[0];
				 	
				 	create SelectedStage returns:sn;
					SelectedStage s1 <-sn[0];
					
					
					s1.stage<-i;
					s1.subject<-m.sender;
					
	
					l.stageAssigned<-copy(leaf.stageAssigned);
					add s1 to:l.stageAssigned;
					
					
					int counterS<-0;
				 	loop sa over:l.stageAssigned{
						if(sa.stage = i){
							counterS<-counterS+1;
						}
					}
					
					l.totalProfit<-partialProfit+leaf.totalProfit+(counterS/(float(m.contents[4])*totalGuests));
					
					add l.totalProfit to: profits;
					add l to:newLeafs;
			
				}		
		 		remove index:index_of(profits,min(profits)) from:newLeafs;
		 		remove index:index_of(profits,min(profits)) from:newLeafs;
		 		
		 		loop l over:newLeafs{
					decisionsGraph <- decisionsGraph add_node(l);
					decisionsGraph <- decisionsGraph add_edge(leaf::l);
		 		}
		 		
		 	}
	 	// TODO ocio togli sta robaccia
		do end_conversation message: m contents: [ ('') ] ;
	 	}
	}

	reflex allMsgReceived when: msgReceivedCount=totalGuests{
		list<TreeLeaf> bottomLevel<-[];
 		float maxProfit<- -1.0;
 		TreeLeaf bestLeaf<-nil;
 		
 		loop nod over: decisionsGraph.vertices{
 			if(decisionsGraph degree_of nod<=1){
				write "current profit:"+TreeLeaf(nod).totalProfit color:#orange;
				write "stages:";
				
				loop s over:TreeLeaf(nod).stageAssigned{
					write s.stage color:#orange;
				}
				
 				if(TreeLeaf(nod).totalProfit>maxProfit){
 					maxProfit <- TreeLeaf(nod).totalProfit;
 					bestLeaf<- nod;
 				}
 			}
		}
		
		write "best combination is:"+bestLeaf.stageAssigned+" profit:"+bestLeaf.totalProfit color:#red;
		
		loop s over:bestLeaf.stageAssigned{
			write s.subject.name + " go to "+s.stage color:#pink;
			do start_conversation to: list(s.subject) protocol: 'fipa-contract-net' performative: 'propose' contents: [s.stage] ;
		}
		
		msgReceivedCount<-0;
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
