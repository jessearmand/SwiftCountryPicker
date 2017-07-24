// Made by Samuel Beek (github.com/samuelbeek)
/**
    Country object
    contains a name, iso country code and emoji, all strings.
*/

public struct Country {

    /// Name of the country
    public let name: String

    /// Native Name of the country
    public let native: String

    /// ISO country code of the country
    public let iso: String

    /// Emoji flag of the country
    public let emoji: String

    /// Dialing code of the country
    public let dial: String

    /// Flag image of the country
    public let flag: UIImage?

    public var rank: Int = Int.max
}


public protocol CountryPickerDelegate: UIPickerViewDelegate {

    /**
     Called by the CountryPicker when the user selects a country

     - parameter picker:  An object representing the CounrtyPicker requesting the data.
     - parameter country: The Selected Country
     */
    func countryPicker(_ picker: CountryPicker, didSelectCountry country: Country)
}

/**
 The CountryPicker class uses a custom subclass of UIPickerView to display country names and flags (emoji flags) in a slot machine interface. The user can choose a pick a country.
*/
open class CountryPicker : UIPickerView {
  
    /// The current picked Country
    open var pickedCountry : Country?
    
    /// The delegate for the CountryPicker
    open var countryDelegate : CountryPickerDelegate?

    /// The top country codes that are positioned at the top
    open var topISOCountryCodes = [String]() {
        didSet {
            loadData()
        }
    }
    
    /// The Content of the CountryPicker
    internal var countryData = [Country]()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.dataSource = self
        self.delegate = self

        self.backgroundColor = .white

        loadData()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /**
     Loads content from .json file
     */
    fileprivate func loadData() {
        guard let bundleUrl = Bundle(for: CountryPicker.self).url(forResource: "SwiftCountryPicker", withExtension: "bundle") else {
            print("Could not find SwiftCountryPicker.bundle")
            return
        }
        
        let bundle = Bundle(url: bundleUrl)
        guard let url = bundle?.url(forResource: "EmojiCountryCodes", withExtension: "json") else {
            print("Could not find EmojiCountryCodes.json")
            return
        }
        
        do {
            let jsonData = try Data(contentsOf: url, options: .mappedIfSafe)
            let json = try JSONSerialization.jsonObject(with: jsonData, options: .allowFragments)
            
            var countryCode: String?

            if let local = (Locale.current as NSLocale).object(forKey: NSLocale.Key.countryCode) as? String {
                countryCode = local
            }

            guard let rawCountries = json as? NSArray else {
                print("countries is not an array")
                return
            }
            
            let countries = rawCountries.filter { element in
                guard let country = element as? [String: String] else {
                    return false
                }

                guard let dial = country["dial"] else {
                    return false
                }
                
                return dial.isEmpty == false
            }
            
            countryData = []
            for element in countries {
                guard let subJson = element as? [String: String] else {
                    break
                }

                guard let name = subJson["name"],
                    let native = subJson["native"],
                    let iso = subJson["code"],
                    let emoji = subJson["emoji"],
                    let dial = subJson["dial"] else {

                        print("couldn't parse json")
                        
                        break
                }

                let image = UIImage(named: iso, in: bundle, compatibleWith: nil)
                var country = Country(name: name, native: native, iso: iso, emoji: emoji, dial: dial, flag: image, rank: Int.max)
                
                // set current country if it's the local country
                if country.iso == countryCode {
                    pickedCountry = country
                }
                
                // append country
                if let topCountryIndex = topISOCountryCodes.index(of: country.iso) {
                    country.rank = topCountryIndex
                }

                countryData.append(country)
            }
            
            countryData.sort {
                if $1.rank == Int.max && $0.rank == Int.max {
                    return $1.name > $0.name
                } else {
                    return $1.rank > $0.rank
                }
            }
            self.reloadAllComponents()
            
        } catch {
            print("error reading file")
        }
        
    }
}

extension CountryPicker: UIPickerViewDataSource {

    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return countryData.count
    }

    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

}

extension CountryPicker : UIPickerViewDelegate {
    var flagTag: Int { return 1 }
    var countryNameTag: Int { return 2 }

    public func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let flag = countryData[row].flag
        let name = countryData[row].name
        let native = countryData[row].native
        let dial = countryData[row].dial

        var text = "\(name) (\(native))\u{202A} +\(dial)\u{202C}"
        if native.isEmpty {
            text = "\(name) +\(dial)"
        }

        let mutableAttributedText = NSMutableAttributedString(string: text)

        let dialRange = NSString(string: mutableAttributedText.string).range(of: "+\(dial)")
        mutableAttributedText.setAttributes(
            [
                NSAttributedStringKey.foregroundColor: UIColor.lightGray
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
            let horizontalConstraints = NSLayoutConstraint.constraints(withVisualFormat: horizontalFormat, options: .alignAllCenterY, metrics: nil, views: views)

            let flagHeight: CGFloat = 3/4 * flagWidth
            let verticalFormat = "V:[flagView(\(flagHeight))]"
            let verticalConstraints = NSLayoutConstraint.constraints(withVisualFormat: verticalFormat, options: .alignAllCenterY, metrics: nil, views: ["flagView": flagView])

            NSLayoutConstraint.activate(horizontalConstraints)
            NSLayoutConstraint.activate(verticalConstraints)

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

    public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        pickedCountry = countryData[row]
        if let countryDelegate = self.countryDelegate {
            countryDelegate.countryPicker(self, didSelectCountry: countryData[row])
        }
    }

}

extension CountryPicker {

    public func country(withDialNumber dial: String) -> Country? {
        let matchedCountries = countryData.filter { (country) -> Bool in
            return country.dial == dial
        }

        return matchedCountries.first
    }

    public func country(withName name: String) -> Country? {
        let matchedCountries = countryData.filter { (country) -> Bool in
            return country.name == name
        }

        return matchedCountries.first
    }

    public func country(atRow row: Int) -> Country {
        return countryData[row]
    }

}
