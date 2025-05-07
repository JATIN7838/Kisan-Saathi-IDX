import firebase_admin
from firebase_admin import credentials, firestore

class FirebaseManager:
    def __init__(self ):
        if not firebase_admin._apps:
            cred = credentials.Certificate('/home/jatin/Desktop/coding/datasets/service.json')
            firebase_admin.initialize_app(cred)
        self.db = firestore.client()

    def set_document(self, collection_name, document_id, data):
        # try:
        doc_ref = self.db.collection(collection_name).document(document_id)
        doc_ref.set(data)
        return 1
        # except Exception as e:
        #     return f"Error setting document: {str(e)}"

    def get_document(self, collection_name, document_id):
        try:
            doc_ref = self.db.collection(collection_name).document(document_id)
            doc = doc_ref.get()
            if doc.exists:
                return doc.to_dict()
            else:
                return f"Document {document_id} does not exist in {collection_name}."
        except Exception as e:
            return f"Error retrieving document: {str(e)}"

    def delete_document(self, collection_name, document_id):
        try:
            doc_ref = self.db.collection(collection_name).document(document_id)
            doc_ref.delete()
            return f"Document {document_id} successfully deleted from {collection_name}."
        except Exception as e:
            return f"Error deleting document: {str(e)}"