/**
 * The contents of this file are subject to the license and copyright
 * detailed in the LICENSE and NOTICE files at the root of the source
 * tree and available online at
 *
 * http://www.dspace.org/license/
 */
package com.imc.dspace.app.xmlui.aspect.myir;

import com.imc.dspace.myir.EPersonProfile;
import org.apache.avalon.framework.parameters.Parameters;
import org.apache.cocoon.ProcessingException;
import org.apache.cocoon.environment.ObjectModelHelper;
import org.apache.cocoon.environment.Request;
import org.apache.cocoon.environment.SourceResolver;
import org.apache.log4j.Logger;
import org.dspace.app.xmlui.aspect.eperson.EPersonUtils;
import org.dspace.app.xmlui.cocoon.AbstractDSpaceTransformer;
import org.dspace.app.xmlui.wing.Message;
import org.dspace.app.xmlui.wing.WingException;
import org.dspace.app.xmlui.wing.element.*;
import org.dspace.app.xmlui.wing.element.List;
import org.dspace.content.Collection;
import org.dspace.content.Community;
import org.dspace.core.ConfigurationManager;
import org.dspace.core.I18nUtil;
import org.dspace.core.LogManager;
import org.dspace.eperson.Group;
import org.dspace.eperson.Subscribe;
import org.xml.sax.SAXException;

import java.io.IOException;
import java.sql.SQLException;
import java.util.*;

/**
 * Display a form that allows the user to edit their profile.
 * There are two cases in which this can be used: 1) when an
 * existing user is attempting to edit their own profile, and
 * 2) when a new user is registering for the first time.
 *
 * There are several parameters this transformer accepts:
 *
 * email - The email address of the user registering for the first time.
 *
 * registering - A boolean value to indicate whether the user is registering for the first time.
 *
 * retryInformation - A boolean value to indicate whether there was an error with the user's profile.
 *
 * retryPassword - A boolean value to indicate whether there was an error with the user's password.
 *
 * allowSetPassword - A boolean value to indicate whether the user is allowed to set their own password.
 *
 * @author Scott Phillips
 */
public class EditProfile extends AbstractDSpaceTransformer
{
    private static Logger log = Logger.getLogger(EditProfile.class);

    /** Language string used: */
    private static final Message T_title_create = message("xmlui.EPerson.EditProfile.title_create");
    private static final Message T_title_update = message("xmlui.MyIR.EditProfile.title_update");
    private static final Message T_dspace_home = message("xmlui.general.dspace_home");
    private static final Message T_trail_new_registration = message("xmlui.EPerson.trail_new_registration");
    private static final Message T_trail_update = message("xmlui.EPerson.EditProfile.trail_update");
    private static final Message T_head_create = message("xmlui.EPerson.EditProfile.head_create");
    private static final Message T_head_update = message("xmlui.MyIR.EditProfile.head_update");
    private static final Message T_email_address = message("xmlui.EPerson.EditProfile.email_address");

    private static final Message T_first_name = message("xmlui.EPerson.EditProfile.first_name");
    private static final Message T_error_required = message("xmlui.EPerson.EditProfile.error_required");
    private static final Message T_last_name = message("xmlui.EPerson.EditProfile.last_name");
    private static final Message T_telephone = message("xmlui.EPerson.EditProfile.telephone");
    private static final Message T_language = message("xmlui.EPerson.EditProfile.Language");

    protected static final Message T_profession = message("xmlui.MyIR.Profile.profession");
    protected static final Message T_affiliation = message("xmlui.MyIR.Profile.affiliation");
    protected static final Message T_website = message("xmlui.MyIR.Profile.website");
    protected static final Message T_set_public = message("xmlui.MyIR.Profile.set.public");
    protected static final Message T_set_public_yes = message("xmlui.MyIR.Profile.set.public.yes");
    protected static final Message T_set_public_no = message("xmlui.MyIR.Profile.set.public.no");

    private static final Message T_create_password_instructions = message("xmlui.EPerson.EditProfile.create_password_instructions");
    private static final Message T_update_password_instructions = message("xmlui.EPerson.EditProfile.update_password_instructions");
    private static final Message T_password = message("xmlui.EPerson.EditProfile.password");
    private static final Message T_error_invalid_password = message("xmlui.EPerson.EditProfile.error_invalid_password");
    private static final Message T_confirm_password = message("xmlui.EPerson.EditProfile.confirm_password");
    private static final Message T_error_unconfirmed_password = message("xmlui.EPerson.EditProfile.error_unconfirmed_password");
    private static final Message T_submit_update = message("xmlui.EPerson.EditProfile.submit_update");
    private static final Message T_submit_create = message("xmlui.EPerson.EditProfile.submit_create");
    private static final Message T_subscriptions = message("xmlui.EPerson.EditProfile.subscriptions");

    private static final Message T_subscriptions_help = message("xmlui.EPerson.EditProfile.subscriptions_help");
    private static final Message T_email_subscriptions = message("xmlui.EPerson.EditProfile.email_subscriptions");
    private static final Message T_select_collection = message("xmlui.EPerson.EditProfile.select_collection");
    private static final Message T_head_auth = message("xmlui.EPerson.EditProfile.head_auth");
    private static final Message T_head_identify = message("xmlui.EPerson.EditProfile.head_identify");
    private static final Message T_head_security = message("xmlui.EPerson.EditProfile.head_change_password");

    private static final Message T_no_name_for_shibboleth = message("xmlui.EPerson.EditProfile.no_name_for_shibboleth");
    private static final Message T_no_password_for_shibboleth = message("xmlui.EPerson.EditProfile.no_password_for_shibboleth");

    private static final Message T_change_password_btn = message("xmlui.EPerson.EditProfile.head_change_password");

    private static Locale[] supportedLocales = getSupportedLocales();

    static {
        Arrays.sort(supportedLocales, new Comparator<Locale>() {
            public int compare(Locale a, Locale b)
            {
                return a.getDisplayName().compareTo(b.getDisplayName());
            }
        });
    }

    /** The email address of the user registering for the first time.*/
    private String email;

    /** Determine if the user is registering for the first time */
    private boolean registering;

    /** Determine if the user is allowed to set their own password */
    private boolean allowSetPassword;

    /** A list of fields in error */
    private java.util.List<String> errors;

    /** ePerson Profile */
    private EPersonProfile personProfile;

    public void setup(SourceResolver resolver, Map objectModel, String src, Parameters parameters)
            throws ProcessingException, SAXException, IOException
    {
        super.setup(resolver,objectModel,src,parameters);

        personProfile = null;

        try {
            personProfile = EPersonProfile.findEPersonsProfile(context, eperson.getID());
        } catch (SQLException e) {
            log.warn(e.getMessage());
        }  catch (NullPointerException e) {
            log.warn(e.getMessage());
        }

        this.email = parameters.getParameter("email","unknown");
        this.registering = parameters.getParameterAsBoolean("registering",false);
        this.allowSetPassword = parameters.getParameterAsBoolean("allowSetPassword",false);

        String errors = parameters.getParameter("errors","");
        if (errors.length() > 0)
        {
            this.errors = Arrays.asList(errors.split(","));
        }
        else
        {
            this.errors = new ArrayList<String>();
        }

        // Ensure that the email variable is set.
        if (eperson != null)
        {
            this.email = eperson.getEmail();
        }
    }

    public void addPageMeta(PageMeta pageMeta) throws WingException
    {
        // Set the page title
        if (registering)
        {
            pageMeta.addMetadata("title").addContent(T_title_create);
        }
        else
        {
            pageMeta.addMetadata("title").addContent(T_title_update);
        }

        pageMeta.addTrailLink(contextPath + "/",T_dspace_home);
        if (registering)
        {
            pageMeta.addTrail().addContent(T_trail_new_registration);
        }
        else
        {
            pageMeta.addTrail().addContent(T_trail_update);
        }
    }


    public void addBody(Body body) throws WingException, SQLException
    {
        // Log that we are viewing a profile
        log.info(LogManager.getHeader(context, "view_profile", ""));

        Request request = ObjectModelHelper.getRequest(objectModel);

        String defaultFirstName="",defaultLastName="",defaultPhone="";
        String defaultProfession="",defaultAffiliation="",defaultWebsiteURL="";
        boolean defaultIsPublic = false;
        String defaultLanguage=null;
        if (request.getParameter("submit") != null)
        {
            defaultFirstName = request.getParameter("first_name");
            defaultLastName = request.getParameter("last_name");
            defaultPhone = request.getParameter("phone");
            defaultLanguage = request.getParameter("language");
            defaultProfession = request.getParameter("profession");
            defaultAffiliation = request.getParameter("affiliation");
            defaultWebsiteURL = request.getParameter("website_url");
            defaultIsPublic = Boolean.valueOf(request.getParameter("is_public"));
        }
        else if (eperson != null)
        {
            defaultFirstName = eperson.getFirstName();
            defaultLastName = eperson.getLastName();
            defaultPhone = eperson.getMetadata("phone");
            defaultLanguage = eperson.getLanguage();

            if (personProfile != null) {
                defaultProfession = personProfile.getProfession();
                defaultAffiliation = personProfile.getAffiliation();
                defaultWebsiteURL = personProfile.getWebsiteUrl();
                defaultIsPublic = personProfile.isPublic();
            }
        }

        String action = contextPath;

        if (registering) {
            action += "/register";
        }
        else {
            action += "/profile";
        }

        Division profile = body.addInteractiveDivision("information", action,Division.METHOD_POST, "primary form-horizontal form-compact");

        if (registering) {
            profile.setHead(T_head_create);
        }
        else {
            profile.setHead(T_head_update);
        }

        // Add the progress list if we are registering a new user
        if (registering) {
            EPersonUtils.registrationProgressList(profile, 2);
        }


        List form = profile.addList("form", List.TYPE_FORM);
        List identity = form.addList("identity", List.TYPE_FORM);

        identity.setHead(T_head_identify);

        identity.addItem().addContent(T_no_name_for_shibboleth);

        // Email
        //identity.addLabel(T_email_address);
        Text mailText = identity.addItem("email", "form-group").addText("email");
        mailText.setLabel(T_email_address);
        mailText.setDisabled(true);
        mailText.setValue(email);

        // First name
        Text firstName = identity.addItem(null, "form-group").addText("first_name");
        firstName.setRequired();
        firstName.setLabel(T_first_name);
        firstName.setValue(defaultFirstName);

        if (errors.contains("first_name")) {
            firstName.addError(T_error_required);
        }

        if (!registering && !ConfigurationManager.getBooleanProperty("xmlui.user.editmetadata", true)) {
            firstName.setDisabled();
        }

        // Last name
        Text lastName = identity.addItem(null, "form-group").addText("last_name");
        lastName.setRequired();
        lastName.setLabel(T_last_name);
        lastName.setValue(defaultLastName);
        if (errors.contains("last_name")) {
            lastName.addError(T_error_required);
        }
        if (!registering &&!ConfigurationManager.getBooleanProperty("xmlui.user.editmetadata", true))
        {
            lastName.setDisabled();
        }

        // Phone
        Text phone = identity.addItem(null, "form-group").addText("phone");
        phone.setLabel(T_telephone);
        phone.setValue(defaultPhone);
        if (errors.contains("phone"))
        {
            phone.addError(T_error_required);
        }
        if (!registering && !ConfigurationManager.getBooleanProperty("xmlui.user.editmetadata", true))
        {
            phone.setDisabled();
        }

        // Language
        Select lang = identity.addItem(null, "form-group").addSelect("language");
        lang.setLabel(T_language);
        if (supportedLocales.length > 0)
        {
            for (Locale lc : supportedLocales)
            {
                lang.addOption(lc.toString(), lc.getDisplayName());
            }
        }
        else
        {
            lang.addOption(I18nUtil.DEFAULTLOCALE.toString(), I18nUtil.DEFAULTLOCALE.getDisplayName());
        }
        lang.setOptionSelected((defaultLanguage == null || defaultLanguage.equals("")) ?
                I18nUtil.DEFAULTLOCALE.toString() : defaultLanguage);
        if (!registering && !ConfigurationManager.getBooleanProperty("xmlui.user.editmetadata", true))
        {
            lang.setDisabled();
        }

        // Profession
        Text professionText = identity.addItem(null, "form-group").addText("profession");
        professionText.setLabel(T_profession);
        professionText.setValue(defaultProfession);

        if (errors.contains("profession")) {
            professionText.addError(T_error_required);
        }
        if (!registering && !ConfigurationManager.getBooleanProperty("xmlui.user.editmetadata", true)) {
            professionText.setDisabled();
        }

        // Affiliation
        Text affiliationText = identity.addItem(null, "form-group").addText("affiliation");
        affiliationText.setLabel(T_affiliation);
        affiliationText.setValue(defaultAffiliation);

        if (errors.contains("affiliation")) {
            affiliationText.addError(T_error_required);
        }
        if (!registering && !ConfigurationManager.getBooleanProperty("xmlui.user.editmetadata", true)) {
            affiliationText.setDisabled();
        }

        // Website URL
        Text websiteUrlText = identity.addItem(null, "form-group").addText("website_url");
        websiteUrlText.setLabel(T_website);
        websiteUrlText.setValue(defaultWebsiteURL);

        if (errors.contains("website_url")) {
            websiteUrlText.addError(T_error_required);
        }
        if (!registering && !ConfigurationManager.getBooleanProperty("xmlui.user.editmetadata", true)) {
            websiteUrlText.setDisabled();
        }

        // Enable Public Profile
        Radio setPublicRadio = identity.addItem(null, "form-group").addRadio("is_public");
        setPublicRadio.setLabel(T_set_public);
        setPublicRadio.addOption(defaultIsPublic, "1", T_set_public_yes);
        setPublicRadio.addOption(!defaultIsPublic, "0", T_set_public_no);

        if (!registering && !ConfigurationManager.getBooleanProperty("xmlui.user.editmetadata", true)) {
            setPublicRadio.setDisabled();
        }

        // Add middle way save button
        if (!registering) {
            Button firstSubmit = form.addItem().addButton("submit");
            firstSubmit.setValue(T_submit_create);
        }

        // Subscriptions
        if (!registering)
        {
            List subscribe = form.addList("subscriptions",List.TYPE_FORM);
            subscribe.setHead(T_subscriptions);

            subscribe.addItem(T_subscriptions_help);

            Collection[] currentList = Subscribe.getSubscriptions(context, context.getCurrentUser());
            Collection[] possibleList = Collection.findAll(context);

            Select subscriptions = subscribe.addItem().addSelect("subscriptions");
            subscriptions.setLabel(T_email_subscriptions);
            subscriptions.setHelp("");
            subscriptions.enableAddOperation();
            subscriptions.enableDeleteOperation();

            subscriptions.addOption(-1,T_select_collection);
            for (Collection possible : possibleList)
            {
                Community temp=(Community) possible.getParentObject();
                String current_name=temp.getName()+" > "+ possible.getMetadata("name");

                try {
                    while (temp.getParentObject()!=null)
                    {
                        temp=(Community)temp.getParentObject();
                        current_name=temp.getName()+" > "+ current_name;
                    }
                } catch (SQLException e) {
                    e.printStackTrace();  //To change body of catch statement use File | Settings | File Templates.
                }
                if (current_name.length() > 120)
                {
                    current_name = current_name.substring(0, 67) + "..."+current_name.substring(current_name.length()-120);
                }

                /*String name = possible.getParentObject().getName() + " > " + possible.getMetadata("name");
               if (name.length() > 80)
               {
                   name = name.substring(0, 77) + "...";
               } */
                subscriptions.addOption(possible.getID(), current_name);
            }

            for (Collection collection: currentList)
            {
                subscriptions.addInstance().setOptionSelected(collection.getID());
            }
        }


        if (allowSetPassword)
        {
            List security = form.addList("security",List.TYPE_FORM);
            security.setHead(T_head_security);

            if (registering)
            {
                security.addItem().addContent(T_create_password_instructions);
            }
            else
            {
                security.addItem().addContent(T_update_password_instructions);
                security.addItem().addContent(T_no_password_for_shibboleth);
            }


            Field password = security.addItem(null, "form-group").addPassword("password");
            password.setLabel(T_password);
            if (registering)
            {
                password.setRequired();
            }
            if (errors.contains("password"))
            {
                password.addError(T_error_invalid_password);
            }

            Field passwordConfirm = security.addItem(null, "form-group").addPassword("password_confirm");
            passwordConfirm.setLabel(T_confirm_password);
            if (registering)
            {
                passwordConfirm.setRequired();
            }
            if (errors.contains("password_confirm"))
            {
                passwordConfirm.addError(T_error_unconfirmed_password);
            }
        }

        Button submit = form.addItem().addButton("submit");
        if (registering)
        {
            submit.setValue(T_submit_update);
        }
        else
        {
            //submit.setValue(T_submit_create);
            submit.setValue(T_change_password_btn);
        }

        profile.addHidden("eperson-continue").setValue(knot.getId());



        if (!registering)
        {
            // Add a list of groups that this user is apart of.
            Group[] memberships = Group.allMemberGroups(context, context.getCurrentUser());


            // Not a member of any groups then don't do anything.
            if (!(memberships.length > 0))
            {
                return;
            }

            List list = profile.addList("memberships");
            list.setHead(T_head_auth);
            for (Group group: memberships)
            {
                list.addItem(group.getName());
            }
        }
    }

    /**
     * Recycle
     */
    public void recycle()
    {
        this.email = null;
        this.errors = null;
        super.recycle();
    }

    /**
     * get the available Locales for the User Interface as defined in dspace.cfg
     * property webui.supported.locales
     * returns an array of Locales or null
     *
     * @return an array of supported Locales or null
     */
    private static Locale[] getSupportedLocales() {
        // modified by aanagnostopoulos
        String ll = ConfigurationManager.getProperty("webui.supported.locales");
        // END aanagnostopoulos
        if (ll != null)
        {
            return I18nUtil.parseLocales(ll);
        }
        else
        {
            Locale result[] = new Locale[1];
            result[0] =  I18nUtil.DEFAULTLOCALE;
            return result;
        }
    }
}
