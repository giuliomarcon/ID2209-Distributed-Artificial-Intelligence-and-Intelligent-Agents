/***
* Name: ATM
* Author: giuliomarcon
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model ATM
import "finalProject_0.gaml"

species ATM skills:[fipa]{
	reflex giveCash when: !empty(requests) {
		message m <- requests[0];
		int amount <- int(m.contents[0]);
		
		do agree message: m contents: [amount];
	}
	
	aspect default{
		draw cone3D(5, 10) at:location color: #gold;
	}
	
}





