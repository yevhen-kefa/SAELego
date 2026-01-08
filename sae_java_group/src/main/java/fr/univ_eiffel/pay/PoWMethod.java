package fr.univ_eiffel.pay;

import java.io.IOException;
import java.util.HexFormat;

import com.google.gson.Gson;

public class PoWMethod implements PayMethod {

    public static final Solver POW_SOLVER = new Solver("SHA-256");
    private final FactoryClient client;
    private Gson gson = new Gson();

    public record Challenge(String data_prefix, String hash_prefix) {}
    
    public record ChallengeAnswer(String dataPrefix, String hashPrefix, String answer) {}

    public PoWMethod(FactoryClient client) {
        this.client = client;
    }

    // Fetches a new PoW challenge
    public Challenge fetchChallenge() throws IOException {
        Challenge challenge = gson.fromJson(client.billingChallenge(), Challenge.class);
        if (challenge.data_prefix() == null) {
            System.err.println("CRITICAL: Challenge fields are NULL. Check JSON mapping.");
        }
        System.err.println("Received PoW challenge: " + challenge);
        return challenge;
    }

    // Solves the challenge
    public ChallengeAnswer solveChallenge(Challenge challenge) {
        var startTime = System.nanoTime();
        
        byte[] dataPrefix = HexFormat.of().parseHex(challenge.data_prefix());
        byte[] hashPrefix = HexFormat.of().parseHex(challenge.hash_prefix());
        
        byte[] solved = POW_SOLVER.solve(dataPrefix, hashPrefix);
        
        System.err.println("Challenge solved in " + (System.nanoTime() - startTime)/1e9 + " seconds");
        
        return new ChallengeAnswer(challenge.data_prefix(), challenge.hash_prefix(), HexFormat.of().formatHex(solved));
    }

    // Submits the solution
    public void submitAnswer(ChallengeAnswer solution) throws IOException {
        client.billingChallengeAnswer(solution.dataPrefix(), solution.hashPrefix(), solution.answer());
    }

    // Pays the requested amount by solving challenges
    public void pay(double amount) throws IOException {
        double money = 0;
        while (money < amount) {
            Challenge challenge = fetchChallenge();
            if (challenge != null && challenge.data_prefix() != null) {
                ChallengeAnswer answer = solveChallenge(challenge);
                submitAnswer(answer);
                System.out.println("Mining progress... Current balance: " + client.balance());
                money++;
            } else {
                System.err.println("Error fetching challenge, retrying...");
            }
        }
        System.out.println("Mining complete. Total earned in this session: " + money);
    }
}