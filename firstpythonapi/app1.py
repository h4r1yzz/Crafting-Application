from flask import Flask, jsonify, request                                                                                             
import firebase_admin                                                                                                            
from firebase_admin import credentials, firestore                                                                                          
import pandas as pd
from sklearn.feature_extraction.text import TfidfVectorizer                                                                               
from sklearn.metrics.pairwise import cosine_similarity                                                                                          

app = Flask(__name__)

# Initialize Firebase Admin SDK
cred = credentials.Certificate('/Users/harry/Downloads/testingagain-21dd6-firebase-adminsdk-j46xq-f8f475e74d.json')
firebase_admin.initialize_app(cred)

# Initialize Firestore client
db = firestore.client()
def fetch_data():
    # Fetch user data and their wishlist
    users_ref = db.collection('users').stream()
    users_data = []
    for user in users_ref:
        user_dict = user.to_dict()
        user_dict['id'] = user.id  # Store the user ID
        wishlist_ref = db.collection('users').document(user.id).collection('wishlist').stream()
        user_dict['wishlist'] = [item.to_dict() for item in wishlist_ref]
        users_data.append(user_dict)

    # Fetch project data and their comments with ratings
    projects_ref = db.collection('projects').stream()
    projects_data = []
    for project in projects_ref:
        project_dict = project.to_dict()
        project_dict['id'] = project.id  
        comments_ref = db.collection('projects').document(project.id).collection('comments').stream()
        project_dict['comments'] = [comment.to_dict() for comment in comments_ref]
        projects_data.append(project_dict)

    return users_data, projects_data

def build_interaction_matrix(users_data, projects_data):
    project_ids = [project['id'] for project in projects_data]
    user_ids = [user['id'] for user in users_data]

    # Initialize an empty matrix
    interaction_matrix = pd.DataFrame(0, index=user_ids, columns=project_ids)

    # Fill the matrix with ratings from comments and wishlist
    for user in users_data:
        for wishlist_item in user['wishlist']:
            project_id = wishlist_item['projectId']
            if project_id in interaction_matrix.columns:
                interaction_matrix.at[user['id'], project_id] = 1  # Wishlist interaction

        for project in projects_data:
            for comment in project['comments']:
                if comment['commentedBy'] == user['id']:
                    interaction_matrix.at[user['id'], project['id']] = comment['rating']

    return interaction_matrix

def calculate_similarity(interaction_matrix):
    # Normalize ratings (subtract mean rating of each user)
    interaction_matrix_norm = interaction_matrix.subtract(interaction_matrix.mean(axis=1), axis=0).fillna(0)
    
    # Calculate cosine similarity between users
    similarity_matrix = pd.DataFrame(cosine_similarity(interaction_matrix_norm),
                                     index=interaction_matrix.index,
                                     columns=interaction_matrix.index)
    return similarity_matrix

def preprocess_text(text):
    # This function can include more preprocessing steps like removing stop words, stemming, etc.
    return text.lower()

def build_tfidf_matrix(projects_data):
    descriptions = [preprocess_text(project['description']) for project in projects_data]
    vectorizer = TfidfVectorizer()
    tfidf_matrix = vectorizer.fit_transform(descriptions)
    return tfidf_matrix, vectorizer

def content_based_score(project_id, user_data, projects_data, tfidf_matrix, vectorizer):
    user_projects = user_data['wishlist']
    user_project_ids = [p['projectId'] for p in user_projects]
    user_project_descriptions = [project['description'] for project in projects_data if project['id'] in user_project_ids]
    
    if not user_project_descriptions:
        return 0
    
    user_tfidf_matrix = vectorizer.transform(user_project_descriptions)
    project_idx = next(i for i, p in enumerate(projects_data) if p['id'] == project_id)
    project_tfidf_vector = tfidf_matrix[project_idx]
    
    cosine_similarities = cosine_similarity(project_tfidf_vector, user_tfidf_matrix)
    return cosine_similarities.mean()

def normalize_series(series):
    std_dev = series.std()
    return (series - series.mean()) / (std_dev if std_dev != 0 else 1)

def hybrid_recommend_projects(user_id, interaction_matrix, similarity_matrix, projects_data, users_data, tfidf_matrix, vectorizer, top_n=8, alpha=0.7):
    if user_id not in interaction_matrix.index:
        return []

    user_interactions = interaction_matrix.loc[user_id]
    user_data = next(u for u in users_data if u['id'] == user_id)
    similar_users = similarity_matrix[user_id].sort_values(ascending=False).index[1:]

    cf_scores = pd.Series(0, index=interaction_matrix.columns)
    for similar_user in similar_users:
        similarity_score = similarity_matrix.at[user_id, similar_user]
        similar_user_interactions = interaction_matrix.loc[similar_user]
        cf_scores += similarity_score * similar_user_interactions

    cf_scores = normalize_series(cf_scores)
    cb_scores = pd.Series(0, index=interaction_matrix.columns)
    for project in projects_data:
        cb_scores[project['id']] = content_based_score(project['id'], user_data, projects_data, tfidf_matrix, vectorizer)

    cb_scores = normalize_series(cb_scores)
    hybrid_scores = alpha * cf_scores + (1 - alpha) * cb_scores
    hybrid_scores = hybrid_scores[user_interactions == 0]

    top_recommendations = hybrid_scores.sort_values(ascending=False).head(top_n).index
    recommended_projects = [project['title'] for project in projects_data if project['id'] in top_recommendations]

    return recommended_projects

@app.route('/recommendations/<user_id>')
def user_recommendations(user_id):
    try:
        users_data, projects_data = fetch_data()
        interaction_matrix = build_interaction_matrix(users_data, projects_data)
        similarity_matrix = calculate_similarity(interaction_matrix)
        tfidf_matrix, vectorizer = build_tfidf_matrix(projects_data)
        recommendations = hybrid_recommend_projects(user_id, interaction_matrix, similarity_matrix, projects_data, users_data, tfidf_matrix, vectorizer)
        return jsonify(recommendations=recommendations)
    except Exception as e:
        return jsonify(error=str(e)), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001, debug=True)
