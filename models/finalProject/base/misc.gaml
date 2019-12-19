/***
* Name: misc
* Author: giuliomarcon
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model misc
import "finalProject_0.gaml"

species Stage{	
	rgb myColor <- #red;
	
	reflex changeColor {
		myColor <- flip(0.5) ? rnd_color(100, 200) : rnd_color(100, 200);
	}
	
	aspect default{
		draw square(30) at: location color: myColor;
	}
}

species ChillArea{	
	rgb myColor <- #lightseagreen;
	
	aspect default{
		draw square(30) at: location color: myColor;
	}
}

species TinderArea{	
	rgb myColor <- #pink;
	
	aspect default{
		draw squircle(15,5) at: location color: myColor;
	}
}


species Entrance{
	
	aspect default{
		draw square(doorSize) at: location color: #green;
	}
}

species Table{
	
	aspect default{
		draw circle(tableRadius) at: location color: #green;
	}
	
	reflex logAgents when: false{
		list<Guest> l <-PartyGuest at_distance (tableRadius*4);
		
		write "["+name+"]:" color:#gold;
		
		loop g over: l { 
			 ask g{
			 	write name+" s"+status;
			 }
		} 
		
		list<Guest> l <-ChillGuest at_distance (tableRadius*4);
		
		write "["+name+"]:" color:#gold;
		
		loop g over: l { 
			 ask g{
			 	write name+" s"+status;
			 }
		} 
		
		write "--------------------";
	}
	
	
	
}

species Exit{
	
	aspect default{
		draw square(doorSize) at: location color: #red;
	}
}

