# Timeout blocking app

This app is a generalization of the app in the repository https://github.com/mk590901/idle_timeout. Unlike the earlier implementation, it takes a more generic approach, offering __auto-blocking__ for an arbitrary Flutter app.

## Business logic of the application

* The application represents a page with a form thas several GUI elements contains data that need to be selected or modified: text, some option and parameters from the proposed list, as well as several buttons for performing operations. These are the most typical widgets of __Flutter__.

* If the user doesn't use the application for a specified period of time, i.e. doesn't touch the screen, the application is automatically locked: a translucent screen appears, blocking access to widgets, as well as exiting the application by pressing the back button.

* You can unlock the application by pressing the __App Unlock__ button on the translucent screen.

* Another useful feature is implemented in the application: on the phone, the application runs in __portrait mode__, on the tablet - in __landscape mode__.

## Key elements of the application:

* Form state (FormBloc).
* Transparent TimeoutScreen.
* Timeout for widgets.
* Unlock button.
* Orientation.


## Movie I  Phone

https://github.com/user-attachments/assets/72c1076e-ccf3-479c-b82d-a160cf50b2a2

## Movie II Tablet

https://github.com/user-attachments/assets/cd4a5d0e-55fa-49d6-a88c-203fced692e6

