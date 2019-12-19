/***
* Name: Supplier
* Author: giuliomarcon
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model Supplier
import "./../base/finalProject_0.gaml"

species Supplier skills:[moving,fipa]{
	rgb myColor <- #lightblue;
	int status <- 0;
	point targetPoint <- nil;
	list<string> beverages <- ['Grappa', 'Montenegro', 'Beer', 'Wine','Soda', 'Cola', 'Juice', 'Julmust'];
	
	reflex moveToTarget when: targetPoint != nil {
		do goto target:targetPoint;
	}
	
	reflex moteToBar when:status = 0 and !empty(informs){
		
		targetPoint <- BarLocation;
		status <- 1;	
	}
	
	reflex reSupply when:status = 1 and (location distance_to(targetPoint) < 1) {
		message m <- informs[0];
		int beverage <- int(m.contents[0]);
		int quantity <- rnd(30,50);
		
		do agree message: m contents: [beverage, quantity];
		targetPoint <- {50,3};
		status <- 2;
	}
	
	reflex initialPosition when: (status = 2) and  (location distance_to(targetPoint) < 1){
		status <- 0;
	}
	 
	 
	aspect default{
		draw sphere(1.5) at:location color: myColor;
	}
		
}

