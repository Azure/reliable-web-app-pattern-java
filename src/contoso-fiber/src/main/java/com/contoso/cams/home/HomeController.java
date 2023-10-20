package com.contoso.cams.home;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;

@Controller
@RequestMapping(value = "/")
public class HomeController {

    @RequestMapping({ "/", "/index.html" })
    public String getIndexPage(Model model) {
        return "redirect:/dashboard";
    }

    @GetMapping(value = "/dashboard")
    public String getHomePage(Model model) {
        return "pages/dashboard";
    }
}
