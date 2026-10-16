package com.example.adt.adtservicea;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

/** Serves the Angular app's index.html for client-side routes so a browser refresh works. */
@Controller
public class SpaController {

    @GetMapping({"/ship", "/track", "/quote"})
    public String forwardToIndex() {
        return "forward:/index.html";
    }
}
