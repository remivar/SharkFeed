//
//  ViewController.swift
//  SharkFeed
//
//  Created by Kishore on 12/09/17.
//  Copyright © 2016 Kishore. All rights reserved.
//

import UIKit

class PhotosViewController: UIViewController, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, UICollectionViewDelegate {

    var photoId: [String] = []
    var pageNumber: Int = 1
    var pageCount: Int = 0
    
    //photo url, lurl, title, description
    var photosDetails: [PhotosDetails] = []
    
    var refreshControl: UIRefreshControl?
    var task: URLSessionDownloadTask?
    var session: URLSession?
    var cache: NSCache<AnyObject, AnyObject>?
 
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var collectionLayout: UICollectionViewFlowLayout!
    
    override func loadView() {
        super.loadView()
        
        //Below is for pull to refresh control and add action
        refreshControl = UIRefreshControl()
        refreshControl?.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl?.addTarget(self, action: #selector(PhotosViewController.refreshphotos), for: UIControlEvents.valueChanged)
        collectionView.addSubview(refreshControl!)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.automaticallyAdjustsScrollViewInsets = false
        self.navigationController?.navigationBar.backgroundColor = UIColor.blue
        

        self.navigationController?.navigationBar.titleTextAttributes = [NSFontAttributeName : UIFont(name: "HelveticaNeue", size: 20)!, NSForegroundColorAttributeName : UIColor.white]
        
        self.title = "SharkFeed"
        
        
        session = URLSession.shared
        task = URLSessionDownloadTask()
        cache = NSCache()
        
        collectionLayout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        collectionLayout.itemSize = CGSize(width: 90, height: 90)
        collectionView!.backgroundColor = UIColor.white
        
        if photosDetails.isEmpty {
            self.photoIdsFromWebService(pageNumber: pageNumber)
        }
    }
    
    //Pull to refresh action method
    func refreshphotos() {
        photoId.removeAll()
        photosDetails.removeAll()
        pageNumber = 1
        self.photoIdsFromWebService(pageNumber: pageNumber)
        refreshControl?.endRefreshing()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    //MARK: Data source
    private func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if photosDetails.isEmpty {
            return 50
        } else {
            return photosDetails.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CustomCollectionViewCellId", for: indexPath) as! CustomCollectionViewCell
        cell.imageView1.image = UIImage(named: "loading.png")
        if !photosDetails.isEmpty {
            if (self.cache?.object(forKey: (indexPath as NSIndexPath).row as AnyObject) != nil) {
                    cell.imageView1.image = self.cache?.object(forKey: (indexPath as NSIndexPath).row as AnyObject) as? UIImage
            } else {
                let photo = self.photosDetails[indexPath.row]
                let url: URL! = URL(string: photo.thumbnailURL as! String)
                task = session?.downloadTask(with: url, completionHandler: { (completionURL, response, error) -> Void in
                    if let data = try? Data(contentsOf: completionURL!) {
                        DispatchQueue.main.async(execute: { () -> Void in
                            if let cell = collectionView.cellForItem(at: indexPath) as? CustomCollectionViewCell{
                                
                                let img:UIImage! = UIImage(data: data)
                                cell.imageView1.image = img
                                self.cache?.setObject(img, forKey: (indexPath as NSIndexPath).row as AnyObject)
                            }
                        })
                    }
                })
                
                task?.resume()
            }
        }
        cell.backgroundColor = UIColor.orange
        return cell
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "photoDetails" {
            let detailsVC = segue.destination as! PhotosDetailsViewController
            let cell = sender as! UICollectionViewCell
            let indexPath = self.collectionView!.indexPath(for: cell)
            detailsVC.selectedPhoto = photosDetails[(indexPath?.row)!]
        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if (scrollView.contentOffset.y >= (scrollView.contentSize.height - scrollView.frame.size.height)) {
            //reached bottom
            pageNumber += 1
            self.photoIdsFromWebService(pageNumber: pageNumber)
        }
    }

    
    //MARK: Methods
    func photoIdsFromWebService(pageNumber: Int) {
        let stringURL = "https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=949e98778755d1982f537d56236bbb42&text=shark&format=json&nojsoncallback=1&page=\(pageNumber)&extras=url_t,url_c,url_l,url_o.json"
        
        let urlwithPercentEscapes = stringURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        
        if let url: NSURL = NSURL(string: urlwithPercentEscapes!) {
            
            let request: NSMutableURLRequest = NSMutableURLRequest(url: url as URL)
            request.httpMethod = "GET"
            
            let session = URLSession.shared
            
            let configTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
                let httpResponse = response as? HTTPURLResponse
                
                if (httpResponse == nil) {
                    return
                }
                
                do {
                    let jsonDict = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary
                    
                    //Getting all data under feed dictionary into a dictionary
                    let photosDict = jsonDict["photos"] as! NSDictionary
                    let photosArray = photosDict["photo"] as! NSMutableArray
                    for photo in photosArray {
                        let dict = photo as! NSDictionary
                        let photoIdOfCurrentObj = dict["id"] as! String
                        //To array
                        self.photoId.append(photoIdOfCurrentObj)
                        
                        //To struct
                        var lthumbnail: NSString = ""
                        
                        let thumbnail = dict.value(forKey: "url_t") as! NSString
                        
                        if dict["url_o"] != nil {
                            lthumbnail = dict.value(forKey: "url_o") as! NSString
                            
                        } else if dict["url_l"] != nil {
                            lthumbnail = dict.value(forKey: "url_l") as! NSString
                            
                        } else if dict["url_c"] != nil {
                            lthumbnail = dict.value(forKey: "url_c") as! NSString
                        } else {
                            lthumbnail = dict.value(forKey: "url_t") as! NSString
                        }
                        
                        let title = dict.value(forKey: "title") as! NSString
                        let photosDetailsCaptured = PhotosDetails(thumbnailURL: thumbnail, lthumbnailURL: lthumbnail, photoTitle: title, photoDescription: "")
                        self.photosDetails.append(photosDetailsCaptured)
                        
                    }

                    self.photosDetailsFromWebService(ids: self.photoId, photosArray: self.photosDetails)
                } catch {
                    print(error)
                }
             
                //Refresh collection view once 100 records have captured in photosDetails struct
                if self.photosDetails.count == self.pageCount+100 {
                    self.downloadCompleted()
                    self.pageCount = self.pageCount+100
                }
                
            })       // End of dataTask
            
            configTask.resume()
        }
    }
    
    
    func photosDetailsFromWebService(ids: [String], photosArray:[PhotosDetails]) { // -> [PhotosDetails] {
        
        let photoIds: [String] = ids
        for (index, id) in photoIds.enumerated() {
            
            var currentPhotoDetailStruct = photosArray[index]
            
            let url: NSURL = NSURL(string:"https://api.flickr.com/services/rest/?method=flickr.photos.getInfo&api_key=949e98778755d1982f537d56236bbb42&photo_id=\(id)&format=json&nojsoncallback=1.json")!
            
            //Creating the request with "GET" header
            let request:NSMutableURLRequest = NSMutableURLRequest(url: url as URL)
            request.httpMethod = "GET"
            
            //Setting the URLsession
            let session = URLSession.shared
            
            let configTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
                let httpResponse = response as? HTTPURLResponse
                if (httpResponse == nil) {
                    return
                }
                do {
                    let jsonDict = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary
                    let photoDictionary = jsonDict["photo"] as! NSMutableDictionary
                    let photoDescriptionDict = photoDictionary.value(forKey: "description") as! NSDictionary
                    let photoDescription = photoDescriptionDict["_content"]
                    currentPhotoDetailStruct.photoDescription = (photoDescription ?? "") as? NSString
                    
                } catch {
                    print(error)
                }
                if self.photosDetails.count == self.pageCount+100 {
                    self.downloadCompleted()
                    self.pageCount = self.pageCount+100
                }
            })
            configTask.resume()
            }
        }

    
    func downloadCompleted() {
        DispatchQueue.main.async {
           self.collectionView.reloadData()  
        }
    }

}

