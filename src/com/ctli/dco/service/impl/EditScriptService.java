package com.ctli.dco.service.impl;

import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;

import com.ctli.dco.service.IEditScriptService;

public class EditScriptService implements IEditScriptService {

	@Override
	public String editScript(String type, String fileName) {
		String script = "";

		BufferedReader br = null;
		FileReader fr = null;
		try {
			fr = new FileReader("combinedScript/"+type+"/"+fileName);
			br = new BufferedReader(fr);
			StringBuilder sb = new StringBuilder();
			String line = br.readLine();

			while (line != null) {
				sb.append(line);
				sb.append("\n");
				line = br.readLine();
			}
			script =  sb.toString();
		} catch (IOException e) {
			System.out.println(e.getMessage());
		} finally {
			try {
				
				fr.close();
				br.close();
			} catch (IOException e) {
				e.printStackTrace();
			}
		}

		return script;
	}

}
