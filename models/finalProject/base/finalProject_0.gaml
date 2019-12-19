/***
* Name: finalProject0
* Author: Nico Catalano
* Description:
* Tags: Tag1, Tag2, TagN
***/
model finalProject0

import "Guest.gaml"
import "Security.gaml"
import "Bar.gaml"
import "Supplier.gaml"
import "ATM.gaml"
import "misc.gaml"

global {
	int doorSize <- 6;
	int tableRadius <- 3;
	point EntranceLocation <- {doorSize / 2, doorSize / 2};
	point ExitLocation <- {100 - doorSize / 2, doorSize / 2};
	point StageLocation <- {85, 85};
	point ChillLocation <- {15, 85};
	point TinderLocation <- {85, 30};
	point BarLocation <- {50, 50};
	point securityLocation <- {3, 50};
	point supplierLocation <- {50, 3};
	point ATMLocation <- {50, 90};

	// Threshold at which the bartender will call the security
	float drunknesThreshold <- 0.9;
	// number of iterations guest have to talk for
	int WAITING_ITERATIONS <- 50;
	int tablePerRow <- 5;
	point tableInitialPosion <- {10, 10};
	list<point> tablePositions;
	list<bool> tableBookings;
	//ture table booked, false not
	int numberOfChill <- 0;
	int maxChill <- 20;
	int numberOfParty <- 0;
	int maxParty <- 20;
	int tableNumber <- 15;
	float communicationIncreasigFactor <- 0.1;

	init {
	//init table positions
		point tablePosion <- tableInitialPosion;
		loop i from: 0 to: (tableNumber - 1) {
			if ((i mod tablePerRow) = 0 and i > 1) {
				tablePosion <- tableInitialPosion + {(i / tablePerRow) * tableRadius * 4.5, 0};
			} else if (i >= 1) {
				tablePosion <- tablePosion + {0, tableRadius * 2.5};
			}

			add tablePosion to: tablePositions;
			add false to: tableBookings;
			create Table number: 1 {
			//location <- tablePosion;
				location <- tablePositions[i];
			}

		}

		write tablePositions;
		create Entrance number: 1 {
			location <- EntranceLocation;
		}

		create Exit number: 1 {
			location <- ExitLocation;
		}

		create Stage number: 1 {
			location <- StageLocation;
		}

		create ChillArea number: 1 {
			location <- ChillLocation;
		}

		create TinderArea number: 1 {
			location <- TinderLocation;
		}

		create Bar number: 1 {
			location <- BarLocation;
		}

		create Security number: 1 {
			location <- securityLocation;
		}

		create Supplier number: 1 {
			location <- supplierLocation;
		}
		
		create ATM number: 1 {
			location <- ATMLocation;
		}

	}

	reflex spawnChillGuest when: numberOfChill < maxChill {
		create ChillGuest number: 1 {
			location <- EntranceLocation;
		}

		numberOfChill <- numberOfChill + 1;
	}

	reflex spawnPartyGuest when: numberOfParty < maxParty {
		create PartyGuest number: 1 {
			location <- EntranceLocation;
		}

		numberOfParty <- numberOfParty + 1;
	}

}

experiment Festival type: gui {
	output {
		display map type: opengl {
			species Entrance;
			species Exit;
			species Stage;
			species ChillArea;
			species TinderArea;
			species Bar;
			species Table;
			species Supplier;
			species ChillGuest;
			species PartyGuest;
			species Security;
			species ATM;
		}

		//TODO: all'inizio non va perché non c'è nessuno
		//		 display "my_display" {
		//        chart "my_chart" type: histogram {
		//        
		//        //TODO perché non va con la classe pafre guest?
		//        //we display the drunkness of agent Guest in 20 ranges computed among the ages between 0 and drunknesThreshold.
		//        datalist (distribution_of(PartyGuest collect each.drunkness,20,0,drunknesThreshold) at "legend") 
		//            value:(distribution_of(PartyGuest collect each.drunkness,20,0,drunknesThreshold) at "values");      
		//        
		//        }
		//    }
	}

}
