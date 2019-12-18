/***
* Name: Security
* Author: giuliomarcon
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model Security
import "./../base/finalProject_0.gaml"

species Security skills:[moving, fipa]{
	rgb myColor <- #red;
	Guest target <- nil;
	int status <- 0;
	
	/*
	 * status
	 * 0: in resting position
	 * 1: received report, going to target
	 * 2: said to target to leave
	 * 3: reached exit
	 */
	reflex changeColor{
		if myColor = #red {
			myColor<-#blue;
		}else{
			myColor <-#red;
		}
	}
	
	reflex initialPosition when: target=nil {
		do goto target: {3,50};
		status <- 0;
	}
	
	reflex gotReport when:status = 0 and !empty(informs){
		message m <- informs[0];
		Guest g<-m.contents[0];
		target<-g;
		
		status <- 1;
		
		//write "got a report of :"+ g color:#pink;
	}
	
	reflex kickOff when:status=1 and target != nil and location distance_to(target) < 1 {
		do start_conversation to: [target] protocol: 'fipa-contract-net' performative: 'inform' contents: [ExitLocation] ;
		status <- 2;
	}
	reflex arriveToExit when: status =2 and location distance_to(ExitLocation) < 9 {
		target<-nil;
		status<-3;
		
	}
	reflex moveToTarget when: target != nil {
		do goto target:target;
	}
	
	aspect default{
		draw sphere(1.5) at:location color: myColor;
	}
	reflex logSecurity when:false{
		write "status:"+status;
	}
	

}