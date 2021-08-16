//
//  GuideView.swift
//  GA-TB-Reference-Guide
//
//  Created by Morgan Greenleaf on 8/6/21.
//

import SwiftUI

struct GuideView: View {
    
    
    var body: some View {
        
        // For the Guide View, we wrap it in a NavigationView
        NavigationView {
            
            // TODO: Maybe turn this into a lazyVGrid?
            // TODO: Add shadow
            // TODO: Correct links when content ready
            VStack {
                
                HStack {
                    Spacer()
                    NavigationLink(destination: ChapterListView()) {
                    Text("All Chapters >")
                        .foregroundColor(.black)
                    }.padding(.top)
                    .padding(.horizontal)
                    
                }
                
                HStack {
                    NavigationLink(destination: ContentView(chapter: IIA)) {
                        Text("Epidemiology")
                        .frame(minWidth: 0, maxWidth: 160, minHeight: 30,maxHeight: 77)
                        .padding()
                        .foregroundColor(.black)
                            .background(Color.customLightBrown)
                        .cornerRadius(5)
                        .multilineTextAlignment(.center)
                    }
                    
                    NavigationLink(destination: ContentView(chapter: IIA)) {
                        Text("LTBI Diagnosis")
                        .frame(minWidth: 10, maxWidth: 160, minHeight: 30,maxHeight: 77)
                        .padding()
                            .foregroundColor(.black)
                        .background(Color.customLightBrown)
                        .cornerRadius(5)
                            .multilineTextAlignment(.center)
                            
                    }
                }
                .padding(.leading)
                .padding(.trailing)
                    
                HStack {
                    NavigationLink(destination: ContentView(chapter: IIA)) {
                        Text("LTBI Diagnosis")
                        .frame(minWidth: 0, maxWidth: 160, minHeight: 30,maxHeight: 77)
                            .padding()
                        .foregroundColor(.black)
                        .background(Color.customLightBrown)
                        .cornerRadius(5)
                            .multilineTextAlignment(.center)
                            
                    }
                    NavigationLink(destination: ContentView(chapter: IIA)) {
                        Text("LTBI Diagnosis")
                        .frame(minWidth: 0, maxWidth: 160, minHeight: 30,maxHeight: 77)
                        .padding()
                        .foregroundColor(.black)
                            .background(Color.customLightBrown)
                        .cornerRadius(5)
                        .multilineTextAlignment(.center)
                    }
                }
                .padding(.leading)
                .padding(.trailing)
                
                
                // Charts
                HStack {
                    Text("Charts")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding(.leading)
                        
                        
                    Spacer()
                    Text("All Charts >")
                        .padding(.trailing)
                        
                }.padding(.top)
                
                HStack {
                    NavigationLink(destination: ContentView(chapter: IIA)) {
                        Text("LTBI Regimens")
                        .frame(minWidth: 0, maxWidth: 160, minHeight: 45)
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.customDarkBrown)
                        .cornerRadius(5)
                        .multilineTextAlignment(.center)
                            
                    }
                    NavigationLink(destination: ContentView(chapter: IIA)) {
                        Text("Dosages")
                        .frame(minWidth: 0, maxWidth: 160, minHeight: 45)
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.customDarkBrown)
                        .cornerRadius(5)
                        .multilineTextAlignment(.center)
                            
                    }
                    NavigationLink(destination: ContentView(chapter: IIA)) {
                        Text("Drug Adverse")
                        .frame(minWidth: 0, maxWidth: 160, minHeight: 45)
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.customDarkBrown)
                        .cornerRadius(5)
                        
                            .multilineTextAlignment(.center)
                            
                    }
                }
                .padding(.leading)
                .padding(.trailing)
                
                HStack {
                    NavigationLink(destination: ContentView(chapter: IIA)) {
                        Text("LTBI Regimens")
                        .frame(minWidth: 0, maxWidth: 160, minHeight: 45)
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.customDarkBrown)
                        .cornerRadius(5)
                        
                            .multilineTextAlignment(.center)
                            
                    }
                    NavigationLink(destination: ContentView(chapter: IIA)) {
                        Text("Dosages")
                        .frame(minWidth: 0, maxWidth: 160, minHeight: 45)
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.customDarkBrown)
                        .cornerRadius(5)
                     
                            .multilineTextAlignment(.center)
                            
                    }
                    NavigationLink(destination: ContentView(chapter: IIA)) {
                        Text("Drug Adverse")
                        .frame(minWidth: 0, maxWidth: 160, minHeight: 45)
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.customDarkBrown)
                        .cornerRadius(5)
                        
                            .multilineTextAlignment(.center)
                            
                    }
                }.padding(.bottom)
                .padding(.leading)
                .padding(.trailing)
                Spacer()
                    
            }
        
            .navigationTitle("Guide")
            .navigationBarTitleDisplayMode(/*@START_MENU_TOKEN@*/.inline/*@END_MENU_TOKEN@*/)
        }
       
        
            
        }
}

struct GuideView_Previews: PreviewProvider {
    static var previews: some View {
        
        
        GuideView()
    }
}
