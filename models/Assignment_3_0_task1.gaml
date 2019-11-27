/***
* Name: Assignment30partebase
* Author: Nico Catalano
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model Festival

/* Insert your model definition here */

global{
	//int N <- rnd(4,20);
	int N<-4; 
    init{
        create Queen number: N{
        	//TODO ci ho messo [rnd(0,N-1),rnd(0,N-1)] prima era [rnd(0,N),0]
        	int x <- 0;
        	int y <- 0;
           location <- ChessBoard[x,y].location;
           write "spawned:"+name+" at:"+x+";"+y;
        }
        
    }
    list<Queen> queens;
    list<ChessBoard> ChessBoards;
    string availablePositionMSG  <- "providePositionAvailable";
    string newAvailablePositionMSG  <- "provideNewPositionAvailable";
    
}

grid ChessBoard skills:[fipa] width:N height:N neighbors:N {

	rgb color <- bool(((grid_x + grid_y) mod 2)) ? #black : #sandybrown;
	bool busy <- false;
	init{
		add self to: ChessBoards;
   }
 
}

species Queen skills:[fipa]{
	int status<-0;
    int queenIndex;
    int AvPositionIndex;
	list<point> availablePositions<-[];
	list<point> positionSuccessor<-[];
	
	init{
        add self to: queens;
//        busy <- false;
        queenIndex <- int(queens[length(queens) -1]);
        if(queenIndex=0){
        	int i;
        	int j;
        	
        	loop i from: 0 to: N-1 {
			     loop j from: 0 to: N-1{
        			add {i,j} to: availablePositions;
			     } 
			}
			//location <- ChessBoard[availablePositions.x].location;	
			
//			write name+" AVList: "+availablePositions color:#pink;
//			write name+" location values: "+availablePositions[0] color:#pink;
//			write name+" location: "+location color:#pink;
			
//			loop i from: 0 to: N-1 {
//			     loop j from: 0 to: N-1{
//			     	if(i!=location.x and j!=location.y and (int(location.x)-i)!=(int(location.y)-j) and (int(location.x)-i)!=(j-int(location.y))){
//        				add {i,j} to: positionSuccessor;	
//    				}
//			     } 
//			}
			positionSuccessor<- getPS(availablePositions);
//			write name+" positionSuccessor: "+positionSuccessor color:#pink;
			AvPositionIndex<-0;
			status<-2;
		}
        //TODO check sta roba
//        if(length(queens) = N ){
//            do start_conversation with:(to: list(queens[0]), protocol: 'fipa-contract-net', performative: 'inform', contents: ['NextQueen']);        
//            write "Start finding position!";
//        }
        
    }
    
    reflex askAV when: queenIndex=1 and length(availablePositions)=0 and status = 0{
    	//Need to ask the previous
    	status<-1;
    	write name+" is asking to "+queens[queenIndex-1].name color:#green;
		do start_conversation to: list(queens[queenIndex-1]) protocol: 'fipa-contract-net' performative: 'request' contents: [availablePositionMSG] ;
    }
    
    
    reflex replyAV when:length(requests)>0 and status=2{
    	message m <-requests[0];
    	string reqMSG<-m.contents[0];
    	string sender<-m.sender;
    	
    	write name+" replying to "+sender color:#darkgreen;
		
    	if (reqMSG = availablePositionMSG){
	    	if(length(positionSuccessor)=0){
				write name+" length(positionSuccessor): "+length(positionSuccessor) color:#darkgreen;
    			write name+" asking to "+queens[queenIndex-1].name+ "to move" color:#darkgreen;
				do start_conversation to: list(queens[queenIndex-1]) protocol: 'fipa-contract-net' performative: 'request' contents: [newAvailablePositionMSG] ;
			}else{
		    	positionSuccessor<- getPS(availablePositions);
	    		write name+" with positionSuccessor:"+positionSuccessor color:#darkgreen;
		    	do inform message: m contents: positionSuccessor;
	    	}
	    	
    	}else if(reqMSG = newAvailablePositionMSG and length(availablePositions)>(AvPositionIndex+1)){
    		AvPositionIndex<-AvPositionIndex+1;
    		write name+" setting AvPositionIndex to:"+AvPositionIndex+ " ("+availablePositions[AvPositionIndex] +") index:"+AvPositionIndex+" av:"+availablePositions color:#darkgreen;
    		
    		positionSuccessor<- getPS(availablePositions);
    		write name+" with positionSuccessor:"+positionSuccessor color:#lightgreen;
    		if(length(positionSuccessor)=0 or AvPositionIndex = length(positionSuccessor)){
    			write name+" asking to "+queens[queenIndex-1].name+ "to move" color:#orange;
    			do start_conversation to: list(queens[queenIndex-1]) protocol: 'fipa-contract-net' performative: 'request' contents: [newAvailablePositionMSG] ;
    		}else{
    			
	    		do inform message: m contents: positionSuccessor;
	    	}
    	}else if(length(availablePositions)=(AvPositionIndex+1)){
    		write name+" scanned all availablePositions, asking :"+queens[queenIndex-1].name+ " to move" color:#gold;
    		do start_conversation to: list(queens[queenIndex-1]) protocol: 'fipa-contract-net' performative: 'request' contents: [newAvailablePositionMSG] ;
    	}
    	
    }
    
 
    reflex gotNewAV when:length(informs)>0{
	
	
    	write name+" got new availablePositions " color:#blue;
    	availablePositions<-informs[0].contents;
    	write name+" availablePositions: "+ availablePositions color:#blue;
    	AvPositionIndex<-0;
   
    	if(queenIndex = (N-1)){
    		status <-5;	
		}else {
	    	
	    	positionSuccessor<- getPS(availablePositions);
	    	write name+" computed new positionSuccessor: "+ positionSuccessor color:#blue;
			if(length(positionSuccessor)=0){
	    		write name+" got positionSucccessor empty asking "+queens[queenIndex-1].name+ "to move" color:#blue;
				do start_conversation to: list(queens[queenIndex-1]) protocol: 'fipa-contract-net' performative: 'request' contents: [newAvailablePositionMSG] ;
			}else {
	    		write name+" got positionSucccessor, giving to: "+queens[queenIndex+1].name color:#blue;
				do start_conversation to: list(queens[queenIndex+1]) protocol: 'fipa-contract-net' performative: 'inform'  contents: positionSuccessor;
			}
	    	
	    	status<-2;
    	
    	}
    }
    

    
    list<point> getPS(list<point> av){
    	list<point> ps <- [];
    	if(av!=nil and length(av)>0){
	    	point currentP <-av[AvPositionIndex];
	    	
	    	loop p over: av { 
	     		if(p.x!=currentP.x 
	     			and p.y!=currentP.y 
	     			and !((int(p.x)-int(currentP.x))=(int(p.y)-int(currentP.y))
	     			or (int(p.x)-int(currentP.x)=-(int(p.y)-int(currentP.y))))) {
	     			
	     			add p to:ps;
	     		}
	 
			}
			
		}	
    	return ps;
    }
    
    reflex updateGraphics when: length(availablePositions)>=1{	
    	//moving to position
    	int loc_x <- availablePositions[AvPositionIndex].x;
    	int loc_y <- availablePositions[AvPositionIndex].y;
    	location <-ChessBoard[loc_x,loc_y].location;
    	
//		write self.name+"  - x:"+loc_x+" y:"+loc_y color:#pink;
    }
    
//    reflex logPositions {
//    	write "log positions qeens:" color:#pink;
//    	
//    	loop q over: queens{
//    		write q.name+"  - "+q.location color:#pink;
//    	}
//    }
    aspect default{
       	draw cone3D(1.3,2.3) at: location color: #antiquewhite ;
    	draw sphere(0.7) at: location + {0, 0, 2} color: #aliceblue ;
    }
}


experiment Festival type: gui {
	/** Insert here the definition of the input and output of the model */
	
	output {
		display map type: opengl {
            grid ChessBoard lines: #black ;
            species Queen;
		}
	}
}
