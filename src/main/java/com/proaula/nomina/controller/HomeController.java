package com.proaula.nomina.controller;

import com.proaula.nomina.security.NominaUserDetails;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class HomeController {

    @GetMapping("/")
    public String home(@AuthenticationPrincipal NominaUserDetails userDetails, Model model) {
        if (userDetails != null) {
            model.addAttribute("usuario", userDetails.getUsuario());
        }
        return "index";
    }
}
