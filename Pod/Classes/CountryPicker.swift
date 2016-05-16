// Made by Samuel Beek (github.com/samuelbeek)
/**
    Country object
    contains a name, iso country code and emoji, all strings.
*/

public struct Country {

    /// Name of the country
    public let name: String!

    /// Native Name of the country
    public let native: String!

    /// ISO country code of the country
    public let iso: String!

    /// Emoji flag of the country
    public let emoji: String!

    /// Dialing code of the country
    public let dial: String!

    /// Flag image of the country
    public let flag: UIImage!
}


public protocol CountryPickerDelegate: UIPickerViewDelegate {

    /**
     Called by the CountryPicker when the user selects a country

     - parameter picker:  An object representing the CounrtyPicker requesting the data.
     - parameter country: The Selected Country
     */
    func countryPicker(picker: CountryPicker, didSelectCountry country: Country)
}

/**
 The CountryPicker class uses a custom subclass of UIPickerView to display country names and flags (emoji flags) in a slot machine interface. The user can choose a pick a country.
*/
public class CountryPicker: UIPickerView {

    /// The current picked Country
    public var pickedCountry: Country?

    /// The delegate for the CountryPicker
    public var countryDelegate: CountryPickerDelegate?

    /// The Content of the CountryPicker
    private var countryData = [Country]()


    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.dataSource = self
        self.delegate = self

        self.backgroundColor = .whiteColor()

        loadData()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /**
     Loads content from .json file
     */
    private func loadData() {
        let bundlePath = NSBundle(forClass: CountryPicker.self).pathForResource("SwiftCountryPicker", ofType: "bundle")

        if let path = NSBundle(path: bundlePath!)!.pathForResource("EmojiCountryCodes", ofType: "json") {

            do {
                let jsonData = try NSData(contentsOfFile: path, options: .DataReadingMappedIfSafe)
                let json = try NSJSONSerialization.JSONObjectWithData(jsonData, options: .AllowFragments)

                var countryCode: String?

                if let local = NSLocale.currentLocale().objectForKey(NSLocaleCountryCode) as? String {
                    countryCode = local
                }


                guard let rawCountries = json as? NSArray else {
                    print("countries is not an array")
                    return
                }

                let countries = rawCountries.filter { country in
                    guard let dial = country["dial"] as? String else {
                        return false
                    }

                    return dial.isEmpty == false
                }

                for subJson in countries {

                    guard let name = subJson["name"] as? String,
                        native = subJson["native"] as? String,
                        iso = subJson["code"] as? String,
                        emoji = subJson["emoji"] as? String,
                        dial = subJson["dial"] as? String else {

                        print("couldn't parse json")

                        break
                    }

                    let image = UIImage(named: iso, inBundle: NSBundle(path: bundlePath!)!, compatibleWithTraitCollection: nil)
                    let country = Country(name: name, native: native, iso: iso, emoji: emoji, dial: dial, flag: image)

                    // set current country if it's the local country
                    if country.iso == countryCode {
                        pickedCountry = country
                    }

                    // append country
                    countryData.append(country)
                }

                countryData.sortInPlace { $1.name > $0.name }
                self.reloadAllComponents()

            } catch {
                print("error reading file")

            }
        }

    }
}

extension CountryPicker : UIPickerViewDataSource {

    var flagTag: Int { return 1 }
    var countryNameTag: Int { return 2 }

    public func pickerView(pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusingView view: UIView?) -> UIView {
        let flag = countryData[row].flag
        let name = countryData[row].name
        let native = countryData[row].native
        let dial = countryData[row].dial

        var text = "\(name) (\(native))\u{202A} +\(dial)\u{202C}"
        if native.isEmpty {
            text = "\(name) +\(dial)"
        }

        let mutableAttributedText = NSMutableAttributedString(string: text)

        let dialRange = NSString(string: mutableAttributedText.string).rangeOfString("+\(dial)")
        mutableAttributedText.setAttributes(
            [
                NSForegroundColorAttributeName: UIColor.lightGrayColor()
            ], range: dialRange)

        let countryNameAndDial = NSAttributedString(attributedString: mutableAttributedText)

        guard let rowView = view else {
            let rowView = UIView(frame: bounds)

            let flagView = UIImageView(image: flag)
            flagView.translatesAutoresizingMaskIntoConstraints = false
            flagView.tag = flagTag
            rowView.addSubview(flagView)

            let countryNameLabel = UILabel()
            countryNameLabel.translatesAutoresizingMaskIntoConstraints = false
            countryNameLabel.tag = countryNameTag
            countryNameLabel.attributedText = countryNameAndDial
            countryNameLabel.adjustsFontSizeToFitWidth = true

            rowView.addSubview(countryNameLabel)

            let flagWidth: CGFloat = 24
            let views = ["flagView": flagView, "countryNameLabel": countryNameLabel]
            let horizontalFormat = "|-8-[flagView(\(flagWidth))]-[countryNameLabel]-|"
            let horizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat(horizontalFormat, options: .AlignAllCenterY, metrics: nil, views: views)

            let flagHeight: CGFloat = 3/4 * flagWidth
            let verticalFormat = "V:[flagView(\(flagHeight))]"
            let verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat(verticalFormat, options: .AlignAllCenterY, metrics: nil, views: ["flagView": flagView])

            NSLayoutConstraint.activateConstraints(horizontalConstraints)
            NSLayoutConstraint.activateConstraints(verticalConstraints)

            return rowView
        }

        if let flagView = rowView.viewWithTag(flagTag) as? UIImageView {
            flagView.image = flag
        }

        if let countryNameLabel = rowView.viewWithTag(countryNameTag) as? UILabel {
            countryNameLabel.attributedText = countryNameAndDial
        }

        return rowView
    }

    public func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return countryData.count
    }

    public func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }

}

extension CountryPicker : UIPickerViewDelegate {

    public func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        pickedCountry = countryData[row]
        if let countryDelegate = self.countryDelegate {
            countryDelegate.countryPicker(self, didSelectCountry: countryData[row])
        }
    }

}
