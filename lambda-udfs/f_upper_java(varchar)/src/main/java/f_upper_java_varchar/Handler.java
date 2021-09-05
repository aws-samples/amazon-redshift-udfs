package f_upper_java_varchar;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;

import java.util.HashMap;
import org.json.*;

public class Handler implements RequestHandler<HashMap<String,Object>, String> {

	@Override
	public String handleRequest(HashMap<String,Object> input, Context context) {
		// TODO Auto-generated method stub
		context.getLogger().log("Input: " + input);

		JSONObject inputJSON = new JSONObject(input);
		JSONArray rows = inputJSON.getJSONArray("arguments");

		JSONArray res = new JSONArray();
		for (int i = 0; i<rows.length(); i++) {
			JSONArray row = rows.getJSONArray(i);
			res.put(row.getString(0).toUpperCase());
		}
		JSONObject results = new JSONObject();
		results.put("results", res);
		return results.toString();
	}

}
