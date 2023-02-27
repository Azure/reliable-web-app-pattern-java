package org.airsonic.player.controller;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.servlet.ModelAndView;
import org.springframework.web.servlet.view.RedirectView;

import javax.servlet.http.HttpServletRequest;

@Controller
@RequestMapping("/")
public class RootController {

    @GetMapping
    protected ModelAndView rootRequest(HttpServletRequest request) {
        return new ModelAndView(new RedirectView("index"));
    }
}
