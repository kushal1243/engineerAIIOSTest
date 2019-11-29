//
//  ViewController.swift
//  EngeerAITestApp
//
//  Created by Kushal Mandala on 29/11/19.
//  Copyright © 2019 Flick Fusion. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate {
    
    var postsListTableView : UITableView!
    var posts : [ AnyObject ] = []
    var refreshControl :  UIRefreshControl = UIRefreshControl()
    var selectedPosts : NSMutableArray = NSMutableArray()
    
    var activityIndicator : UIActivityIndicatorView!
    
    var requestPage : Int = 1

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Selected Posts"+" \(self.selectedPosts.count)"
        
        self.setupPostListTableView()
        self.requestPosts(page: self.requestPage)
        
        // Do any additional setup after loading the view.
    }
    
    func setupPostListTableView() {
        self.postsListTableView = UITableView(frame: CGRect(x: 10, y: 88, width: self.view.frame.size.width - 2*10, height: self.view.frame.size.height-88), style: .grouped)
       self.postsListTableView.register(UITableViewCell.self, forCellReuseIdentifier: "CellID")
        self.postsListTableView.delegate = self
        self.postsListTableView.dataSource = self
        self.view.addSubview(self.postsListTableView)
        
        self.postsListTableView.refreshControl = self.refreshControl
        
        self.refreshControl.addTarget(self, action: #selector(refreshPosts), for: .valueChanged)
        self.refreshControl.attributedTitle = NSAttributedString(string: "Load posts...")
    }
    
    @objc func refreshPosts() {
        
        self.requestPosts(page:1)
        self.refreshControl.endRefreshing()
    }
    
    func requestPosts(page: Int) {
         let requestURLString = "https://hn.algolia.com/api/v1/search_by_date?tags=story&page="+"\(page)"
        print("Request is \(requestURLString)")
        
        URLSession.shared.dataTask(with: URL(string: requestURLString)!) { (data,urlResponse, error) in
            guard data != nil else {
                print("Error \(String(describing: error))")
                return
            }
            
            do {
                let response : AnyObject = try JSONSerialization.jsonObject(with: data!, options: []) as AnyObject
               // print("Response is \(response)")
                
                let postsInfo : [AnyObject] = response.value(forKey: "hits") as! [AnyObject]
                if page == 1 {
                    self.selectedPosts.removeAllObjects()
                    self.posts = postsInfo
                } else {
                    self.appendPosts(additionalPosts: postsInfo)
                }
                
                DispatchQueue.main.async {
                    self.title = "Selected Posts"+" \(self.selectedPosts.count)"
                    self.postsListTableView.reloadData()
                    self.refreshControl.endRefreshing()
                }
            } catch {
                print("Error \(error)")
            }
        }.resume()
    }
    
    func appendPosts(additionalPosts : [AnyObject]) {
        for post in additionalPosts {
            self.posts.append(post)
        }
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "CellID")
        
        let post = self.posts[indexPath.row]
        
        cell.textLabel?.text = post.value(forKey: "title") as? String
        cell.detailTextLabel?.text = (post.value(forKey: "created_at") as! String)
        
        let cellSwitch = UISwitch()
        cellSwitch.tag = indexPath.row+1
        cell.accessoryView = cellSwitch
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedPost = self.posts[indexPath.row]
        
        let cell = tableView.cellForRow(at: indexPath)
        let cellSwitch : UISwitch = cell?.viewWithTag(indexPath.row+1) as! UISwitch
        
        if self.selectedPosts.contains(selectedPost) {
            self.selectedPosts.remove(selectedPost)
            cellSwitch.isOn = false
        } else {
            self.selectedPosts.add(selectedPost)
            cellSwitch.isOn = true
        }
        
        self.title = "Selected Posts"+" \(self.selectedPosts.count)"
    }
    
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == self.posts.count-1 {
            print("Pagination is here")
            self.requestPage += 1
            self.requestPosts(page: self.requestPage)
        }
    }
    

}


