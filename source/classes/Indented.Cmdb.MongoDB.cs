using System;
using System.Collections.Generic;
using MongoDB.Bson;
using MongoDB.Bson.IO;
using MongoDB.Bson.Serialization;
using MongoDB.Driver;

 namespace Indented.Cmdb
 {
     public class MongoDB
     {
        #region Fields
        IMongoClient client;
        IMongoDatabase database;
        IMongoCollection<BsonDocument> collection;
        JsonWriterSettings jsonWriterSettings = new JsonWriterSettings() { OutputMode = JsonOutputMode.Strict };
        #endregion

        #region Constructors
        public MongoDB(MongoUrl Url, string DatabaseName, string CollectionName)
        {
            Connect(Url, DatabaseName, CollectionName);
        }
        #endregion

        #region Properties
        internal IMongoCollection<BsonDocument> Collection
        {
            get { return collection; }
        }

        internal JsonWriterSettings WriterSettings
        {
            get { return jsonWriterSettings; }
        }
        #endregion

        #region Methods
        public void AddDocument(string Document)
        {
            BsonDocument document = ConvertToBson(Document);
            Collection.InsertOne(document);
        }

        public void Connect(MongoUrl url, string DatabaseName, string CollectionName)
        {
            client = new MongoClient(url);
            database = client.GetDatabase(DatabaseName);
            collection = database.GetCollection<BsonDocument>(CollectionName);
        }

        public BsonDocument ConvertToBson(string Document)
        {
            JsonReader jsonReader = new JsonReader(Document);
            BsonDeserializationContext context = BsonDeserializationContext.CreateRoot(jsonReader);

            return collection.DocumentSerializer.Deserialize(context);
        }

        public List<string> FindDocument(string Filter = "", string Projection = "{ }", int Limit = 0, int Skip = 0)
        {
            BsonDocument filter = new BsonDocument();
            if (Filter != string.Empty)
            {
                filter = ConvertToBson(Filter);
            }

            List<string> documents = new List<string>(); 
            Collection.Find<BsonDocument>(filter)
                      .Limit(Limit)
                      .Skip(Skip)
                      .Project(Projection)
                      .ToList()
                      .ForEach(document => documents.Add(document.ToJson(WriterSettings)));

            return documents;
        }
        
        public void RemoveDocument(string Filter)
        {
            BsonDocument filter = ConvertToBson(Filter);
            Collection.DeleteMany(filter);
        }

        public void UpdateDocument(string Filter, string Document, bool Upsert = false)
        {
            BsonDocument filter = ConvertToBson(Filter);
            BsonDocument document = ConvertToBson(Document);
            UpdateOptions updateOptions = new UpdateOptions() { IsUpsert = Upsert };

            Collection.UpdateOne(filter, document, updateOptions);
        }
        #endregion
     }
 }