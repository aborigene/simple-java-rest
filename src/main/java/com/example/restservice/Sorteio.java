package com.example.restservice;
import java.util.Random;

public class Sorteio {
	private final String prize_result;
	

	public Sorteio() {
		int int_random = 0;
        String prize_result = "";
		//try{
			Random rand = new Random(); //instance of random class
            int upperbound = 25;
            //generate random values from 0-24
            int_random = rand.nextInt(upperbound);//*1000;
            if (int_random == 10) prize_result = "winner";
            else prize_result = "looser";
			//System.out.println("Waiting for "+int_random+" seconds.");
			//Thread.sleep(int_random);
		//}
		/*catch(InterruptedException ex){
			System.out.println ("Error while sleeping...");
		}*/
		System.out.println("Starting to create stuff...");
		this.prize_result = prize_result;
		System.out.println("Finished to create stuff...");
	}

	public String getPrizeResult() {
		return prize_result;
	}
}
